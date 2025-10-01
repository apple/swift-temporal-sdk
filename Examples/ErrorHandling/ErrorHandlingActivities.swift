//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Foundation
import Temporal

/// Activities for the travel booking workflow demonstrating error handling patterns.
/// Each activity simulates interactions with external services (booking systems, payment gateways)
/// and demonstrates different error handling scenarios.
@ActivityContainer
struct ErrorHandlingActivities {
    // MARK: - Activity Input Types

    struct FlightReservation: Codable {
        let flightId: String
        let customerId: String
    }

    struct HotelReservation: Codable {
        let hotelId: String
        let customerId: String
    }

    struct PaymentRequest: Codable {
        let customerId: String
        let amount: Double
        let simulateFailure: Bool
    }

    struct CancellationRequest: Codable {
        let reservationId: String
        let simulateFailure: Bool
    }

    // MARK: - Fake Services

    private let reservationService: ReservationService
    private let paymentService: PaymentServiceProtocol

    init(
        reservationService: ReservationService,
        paymentService: PaymentServiceProtocol
    ) {
        self.reservationService = reservationService
        self.paymentService = paymentService
    }

    init() {
        self.reservationService = FakeReservationService()
        self.paymentService = FakePaymentService()
    }

    // MARK: - Activities

    /// Reserves a flight - demonstrates automatic retry on transient failures
    @Activity
    func reserveFlight(input: FlightReservation) async throws -> String {
        print("✈️  Reserving flight \(input.flightId) for customer \(input.customerId)...")

        let reservationId = try await reservationService.reserveFlight(
            flightId: input.flightId,
            customerId: input.customerId
        )

        print("✅ Flight reserved: \(reservationId)")
        return reservationId
    }

    /// Reserves a hotel - demonstrates automatic retry on transient failures
    @Activity
    func reserveHotel(input: HotelReservation) async throws -> String {
        print("🏨 Reserving hotel \(input.hotelId) for customer \(input.customerId)...")

        let reservationId = try await reservationService.reserveHotel(
            hotelId: input.hotelId,
            customerId: input.customerId
        )

        print("✅ Hotel reserved: \(reservationId)")
        return reservationId
    }

    /// Charges payment - demonstrates non-retryable business errors
    @Activity
    func chargePayment(input: PaymentRequest) async throws -> String {
        print("💳 Charging payment of $\(input.amount) for customer \(input.customerId)...")

        if input.simulateFailure {
            // Simulate insufficient funds error (non-retryable)
            print("❌ Payment failed: Insufficient funds")
            throw ApplicationError(
                message: "Insufficient funds to complete purchase",
                type: "InsufficientFunds",
                isNonRetryable: true
            )
        }

        let paymentId = try await paymentService.charge(
            customerId: input.customerId,
            amount: input.amount
        )

        print("✅ Payment successful: \(paymentId)")
        return paymentId
    }

    /// Cancels flight reservation - compensation activity
    @Activity
    func cancelFlight(input: CancellationRequest) async throws {
        print("🔄 Cancelling flight reservation \(input.reservationId)...")

        if input.simulateFailure {
            print("❌ Flight cancellation failed: Airline API timeout")
            throw ApplicationError(
                message: "Airline reservation system unavailable - unable to cancel flight",
                type: "CancellationFailed",
                isNonRetryable: true
            )
        }

        try await reservationService.cancelFlight(reservationId: input.reservationId)

        print("✅ Flight reservation cancelled")
    }

    /// Cancels hotel reservation - compensation activity
    @Activity
    func cancelHotel(input: CancellationRequest) async throws {
        print("🔄 Cancelling hotel reservation \(input.reservationId)...")

        if input.simulateFailure {
            print("❌ Hotel cancellation failed: Hotel booking system unavailable")
            throw ApplicationError(
                message: "Hotel reservation system down - unable to cancel booking",
                type: "CancellationFailed",
                isNonRetryable: true
            )
        }

        try await reservationService.cancelHotel(reservationId: input.reservationId)

        print("✅ Hotel reservation cancelled")
    }
}

// MARK: - Service Protocols

/// Protocol for reservation system operations
protocol ReservationService: Sendable {
    func reserveFlight(flightId: String, customerId: String) async throws -> String
    func reserveHotel(hotelId: String, customerId: String) async throws -> String
    func cancelFlight(reservationId: String) async throws
    func cancelHotel(reservationId: String) async throws
}

/// Protocol for payment gateway operations
protocol PaymentServiceProtocol: Sendable {
    func charge(customerId: String, amount: Double) async throws -> String
}

// MARK: - Fake Service Implementations

/// Simulates a reservation system with transient failures
actor FakeReservationService: ReservationService {
    private var reservations: [String: String] = [:]
    private var attemptCount: [String: Int] = [:]

    func reserveFlight(flightId: String, customerId: String) async throws -> String {
        // Simulate transient failures on first few attempts
        let key = "flight-\(flightId)-\(customerId)"
        let attempts = attemptCount[key, default: 0]
        attemptCount[key] = attempts + 1

        // Fail first 2 attempts to demonstrate retry
        if attempts < 2 {
            try await Task.sleep(for: .milliseconds(100))
            let errorType = attempts == 0 ? "Connection timeout" : "Service temporarily unavailable"
            print("⚠️  Flight reservation attempt \(attempts + 1) failed: \(errorType)")
            throw ApplicationError(
                message: errorType,
                type: "TransientError",
                isNonRetryable: false
            )
        }

        // Succeed on 3rd attempt
        try await Task.sleep(for: .milliseconds(200))
        let reservationId = "FLIGHT-RES-\(UUID().uuidString.prefix(8))"
        reservations[reservationId] = "flight"
        attemptCount[key] = 0  // Reset for next use
        return reservationId
    }

    func reserveHotel(hotelId: String, customerId: String) async throws -> String {
        // Simulate transient failures on first attempt
        let key = "hotel-\(hotelId)-\(customerId)"
        let attempts = attemptCount[key, default: 0]
        attemptCount[key] = attempts + 1

        // Fail first attempt to demonstrate retry
        if attempts < 1 {
            try await Task.sleep(for: .milliseconds(100))
            print("⚠️  Hotel reservation attempt \(attempts + 1) failed: Database connection timeout")
            throw ApplicationError(
                message: "Database connection timeout",
                type: "TransientError",
                isNonRetryable: false
            )
        }

        // Succeed on 2nd attempt
        try await Task.sleep(for: .milliseconds(200))
        let reservationId = "HOTEL-RES-\(UUID().uuidString.prefix(8))"
        reservations[reservationId] = "hotel"
        attemptCount[key] = 0  // Reset for next use
        return reservationId
    }

    func cancelFlight(reservationId: String) async throws {
        try await Task.sleep(for: .milliseconds(150))
        reservations.removeValue(forKey: reservationId)
    }

    func cancelHotel(reservationId: String) async throws {
        try await Task.sleep(for: .milliseconds(150))
        reservations.removeValue(forKey: reservationId)
    }
}

/// Simulates a payment service with idempotency
actor FakePaymentService: PaymentServiceProtocol {
    private var processedPayments: [String: String] = [:]

    func charge(customerId: String, amount: Double) async throws -> String {
        // Simulate payment gateway API call delay
        try await Task.sleep(for: .milliseconds(400))

        // Idempotency: return existing payment ID if already processed
        let idempotencyKey = "\(customerId)-\(amount)"
        if let existingPaymentId = processedPayments[idempotencyKey] {
            return existingPaymentId
        }

        let paymentId = "PAY-\(UUID().uuidString.prefix(12))"
        processedPayments[idempotencyKey] = paymentId
        return paymentId
    }
}
