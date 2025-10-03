//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Temporal

/// Demonstrates error handling and compensation patterns in Temporal workflows.
///
/// This workflow implements a travel booking system that shows:.
/// - Automatic retry with exponential backoff for transient failures
/// - Saga pattern for distributed transaction compensation
/// - Proper error handling with retryable vs non-retryable errors
@Workflow
final class ErrorHandlingWorkflow {
    // MARK: - Input/Output Types

    struct TravelBookingRequest: Codable {
        let customerId: String
        let flightId: String
        let hotelId: String
        let amount: Double
        let simulateFailure: Bool  // For testing compensation scenario
        let simulateCompensationFailure: Bool  // For testing failed compensation
    }

    struct BookingResult: Codable {
        let bookingId: String
        let status: String
        let flightReservationId: String?
        let hotelReservationId: String?
        let paymentId: String?
        let message: String
    }

    // MARK: - Workflow Implementation

    func run(input: TravelBookingRequest) async throws -> BookingResult {
        let bookingId = "BOOKING-\(input.customerId)-\(Int.random(in: 1000...9999))"

        // Track reservations for potential compensation
        var flightReservationId: String?
        var hotelReservationId: String?

        do {
            // Step 1: Reserve flight
            // This activity demonstrates retry on transient failures
            flightReservationId = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.ReserveFlight.self,
                options: .init(
                    startToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(500),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(10),
                        maximumAttempts: 5
                    )
                ),
                input: ErrorHandlingActivities.FlightReservation(
                    flightId: input.flightId,
                    customerId: input.customerId
                )
            )

            // Step 2: Reserve hotel
            // This activity also demonstrates retry on transient failures
            hotelReservationId = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.ReserveHotel.self,
                options: .init(
                    startToCloseTimeout: .seconds(30),
                    retryPolicy: .init(
                        initialInterval: .milliseconds(500),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(10),
                        maximumAttempts: 5
                    )
                ),
                input: ErrorHandlingActivities.HotelReservation(
                    hotelId: input.hotelId,
                    customerId: input.customerId
                )
            )

            // Step 3: Charge payment
            // This demonstrates non-retryable errors (insufficient funds, invalid card)
            let paymentId = try await Workflow.executeActivity(
                ErrorHandlingActivities.Activities.ChargePayment.self,
                options: .init(
                    startToCloseTimeout: .seconds(60),
                    retryPolicy: .init(
                        initialInterval: .seconds(1),
                        backoffCoefficient: 2.0,
                        maximumInterval: .seconds(30),
                        maximumAttempts: 5,
                        nonRetryableErrorTypes: ["InsufficientFunds", "InvalidCard"]
                    )
                ),
                input: ErrorHandlingActivities.PaymentRequest(
                    customerId: input.customerId,
                    amount: input.amount,
                    simulateFailure: input.simulateFailure
                )
            )

            // Success! All steps completed
            return BookingResult(
                bookingId: bookingId,
                status: "confirmed",
                flightReservationId: flightReservationId,
                hotelReservationId: hotelReservationId,
                paymentId: paymentId,
                message: "Travel booking completed successfully"
            )

        } catch {
            // Compensation: Rollback in reverse order
            // This is the Saga pattern - compensate for partial success

            var compensationErrors: [String] = []

            if let hotelResId = hotelReservationId {
                // Cancel hotel reservation
                do {
                    try await Workflow.executeActivity(
                        ErrorHandlingActivities.Activities.CancelHotel.self,
                        options: .init(
                            startToCloseTimeout: .seconds(30),
                            retryPolicy: .init(
                                initialInterval: .milliseconds(500),
                                backoffCoefficient: 2.0,
                                maximumInterval: .seconds(10),
                                maximumAttempts: 3
                            )
                        ),
                        input: ErrorHandlingActivities.CancellationRequest(
                            reservationId: hotelResId,
                            simulateFailure: input.simulateCompensationFailure
                        )
                    )
                } catch {
                    // Track compensation failure
                    compensationErrors.append("Hotel cancellation failed: \(error.localizedDescription)")
                }
            }

            if let flightResId = flightReservationId {
                // Cancel flight reservation
                do {
                    try await Workflow.executeActivity(
                        ErrorHandlingActivities.Activities.CancelFlight.self,
                        options: .init(
                            startToCloseTimeout: .seconds(30),
                            retryPolicy: .init(
                                initialInterval: .milliseconds(500),
                                backoffCoefficient: 2.0,
                                maximumInterval: .seconds(10),
                                maximumAttempts: 3
                            )
                        ),
                        input: ErrorHandlingActivities.CancellationRequest(
                            reservationId: flightResId,
                            simulateFailure: input.simulateCompensationFailure
                        )
                    )
                } catch {
                    // Track compensation failure
                    compensationErrors.append("Flight cancellation failed: \(error.localizedDescription)")
                }
            }

            // If compensation itself failed, this is a critical error requiring manual intervention
            if !compensationErrors.isEmpty {
                let errorMessage = """
                    Critical: Booking failed AND compensation failed. Manual intervention required.
                    Original error: \(error.localizedDescription)
                    Compensation errors:
                    \(compensationErrors.map { "  - \($0)" }.joined(separator: "\n"))
                    Reservations requiring manual cleanup:
                      - Flight: \(flightReservationId ?? "none")
                      - Hotel: \(hotelReservationId ?? "none")
                    """

                throw ApplicationError(
                    message: errorMessage,
                    type: "CompensationFailed",
                    isNonRetryable: true
                )
            }

            // Compensation succeeded - return cancelled status
            return BookingResult(
                bookingId: bookingId,
                status: "cancelled",
                flightReservationId: flightReservationId,
                hotelReservationId: hotelReservationId,
                paymentId: nil,
                message: "Booking failed: \(error.localizedDescription). All reservations cancelled successfully."
            )
        }
    }
}
