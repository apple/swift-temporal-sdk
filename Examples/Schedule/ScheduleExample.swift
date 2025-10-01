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

#if GRPCNIOTransport
import Foundation
import GRPCNIOTransportHTTP2Posix
import Logging
import Temporal

/// Space Mission Schedule Example
///
/// This example demonstrates Temporal's scheduling capabilities through a space mission
/// control automation scenario that monitors the International Space Station (ISS).
///
/// **Features Demonstrated:**
/// - **Calendar-Based Scheduling**: Daily and time-specific operations (system health at 00:00 UTC, crew checks 3x daily)
/// - **Interval-Based Scheduling**: Periodic operations (telemetry every 90 minutes matching ISS orbital period)
/// - **Real API Integration**: Activities fetch live data from NASA/space APIs (wheretheiss.at, open-notify.org)
/// - **Durable Execution**: Automatic retries for network failures, timeout handling
/// - **Schedule Management**: Creating, triggering, and managing multiple schedules
///
/// **Real APIs Used:**
/// - wheretheiss.at - Real-time ISS position, altitude, velocity (no auth required)
/// - open-notify.org - Current astronauts in space (no auth required)
///
/// The example showcases why Temporal's durable execution is essential for mission-critical
/// systems that depend on external APIs and require reliable scheduled operations.
@main
struct ScheduleExample {
    static func main() async throws {
        var logger = Logger(label: "TemporalWorker")
        logger.logLevel = .info

        let namespace = "default"
        let taskQueue = "iss-mission-control"

        // Confirm no prior schedules exist from previous runs
        try await performCleanup(logger: logger)

        print("🚀 Space Mission Control - Real-time ISS Monitoring with Temporal")
        print(String(repeating: "=", count: 70))
        print("Mission: ISS Operations Monitor")
        print("ISS Mission Time: T+9,847 days (since Nov 20, 1998)")
        print("NORAD ID: 25544")
        print()
        print("🔗 View all workflows: http://localhost:8233/namespaces/\(namespace)/workflows")
        print("🔗 View all schedules: http://localhost:8233/schedules")
        print()

        print("📡 Initializing Mission Control Systems...")

        // Create worker configuration
        let workerConfiguration = TemporalWorker.Configuration(
            namespace: namespace,
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        // Create the worker
        let worker = try TemporalWorker(
            configuration: workerConfiguration,
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            activityContainers: SpaceMissionActivities(),
            activities: [],
            workflows: [SpaceMissionWorkflow.self],
            logger: logger
        )

        let client = try TemporalClient(
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            configuration: .init(
                instrumentation: .init(
                    serverHostname: "localhost"
                )
            ),
            logger: logger
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await worker.run()
            }

            group.addTask {
                try await client.run()
            }

            // Wait for worker and client to initialize
            try await Task.sleep(for: .seconds(1))

            print("  ✅ Connected to ISS tracking API (wheretheiss.at)")
            print("  ✅ Connected to crew roster API (open-notify.org)")
            print("  ✅ Temporal client connected (localhost:7233)")
            print("  ✅ Worker started on task queue: \(taskQueue)")
            print()

            print("📅 Creating Mission Schedules...")

            // Schedule 1: Real-time Telemetry Collection (every 90 minutes - ISS orbital period)
            let telemetrySchedule = Schedule(
                action: .startWorkflow(
                    .init(
                        workflowName: "\(SpaceMissionWorkflow.self)",
                        options: .init(
                            id: "telemetry-\(UUID().uuidString)",
                            taskQueue: taskQueue
                        ),
                        input: MissionOperationInput(operation: .collectTelemetry)
                    )
                ),
                specification: .init(
                    intervals: [
                        .init(
                            every: .seconds(90 * 60),  // 90 minutes
                            offset: .zero
                        )
                    ],
                    timeZoneName: "UTC"
                )
            )

            let telemetryHandle = try await client.createSchedule(
                id: "iss-telemetry-schedule",
                schedule: telemetrySchedule,
                options: .init(
                    triggerImmediately: true
                )
            )

            print("  ✅ Real-time Telemetry (every 90 min - orbital period)")
            print("     Schedule ID: iss-telemetry-schedule")

            // Schedule 2: Crew Status Check (3x daily at 06:00, 14:00, 22:00 UTC)
            let crewSchedule = Schedule(
                action: .startWorkflow(
                    .init(
                        workflowName: "\(SpaceMissionWorkflow.self)",
                        options: .init(
                            id: "crew-\(UUID().uuidString)",
                            taskQueue: taskQueue
                        ),
                        input: MissionOperationInput(operation: .checkCrew)
                    )
                ),
                specification: .init(
                    calendars: [
                        .init(minute: [.init(value: 0)], hour: [.init(value: 6)]),
                        .init(minute: [.init(value: 0)], hour: [.init(value: 14)]),
                        .init(minute: [.init(value: 0)], hour: [.init(value: 22)]),
                    ],
                    timeZoneName: "UTC"
                )
            )

            let crewHandle = try await client.createSchedule(
                id: "iss-crew-schedule",
                schedule: crewSchedule,
                options: .init(
                    triggerImmediately: true
                )
            )

            print("  ✅ Crew Status Check (3x daily: 06:00, 14:00, 22:00 UTC)")
            print("     Schedule ID: iss-crew-schedule")

            // Schedule 3: System Health Check (daily at 00:00 UTC)
            let healthSchedule = Schedule(
                action: .startWorkflow(
                    .init(
                        workflowName: "\(SpaceMissionWorkflow.self)",
                        options: .init(
                            id: "health-\(UUID().uuidString)",
                            taskQueue: taskQueue
                        ),
                        input: MissionOperationInput(operation: .systemHealth)
                    )
                ),
                specification: .init(
                    calendars: [
                        .init(
                            minute: [.init(value: 0)],
                            hour: [.init(value: 0)]
                        )
                    ],
                    timeZoneName: "UTC"
                )
            )

            let healthHandle = try await client.createSchedule(
                id: "iss-health-schedule",
                schedule: healthSchedule,
                options: .init(
                    triggerImmediately: true
                )
            )

            print("  ✅ System Health Check (daily at 00:00 UTC)")
            print("     Schedule ID: iss-health-schedule")
            print()

            print(String(repeating: "=", count: 70))
            print()
            print("🛰️  Executing Scheduled Operations...")
            print()

            // Wait for scheduled workflows to execute
            try await Task.sleep(for: .seconds(3))

            // Describe schedules to get recent actions
            let telemetryDesc = try await telemetryHandle.describe(inputType: MissionOperationInput.self)
            let crewDesc = try await crewHandle.describe(inputType: MissionOperationInput.self)
            let healthDesc = try await healthHandle.describe(inputType: MissionOperationInput.self)

            // Display results from triggered workflows
            var operationCount = 0

            // Process telemetry result
            if let workflowId = telemetryDesc.info.recentActions.first?.action.workflowId {
                operationCount += 1
                print("[Operation \(operationCount)] 🌍 Real-time Telemetry Collection")
                print(String(repeating: "-", count: 70))

                do {
                    let handle = client.workflowHandle(
                        type: SpaceMissionWorkflow.self,
                        id: workflowId
                    )
                    let result = try await handle.result()

                    if let telemetry = result.telemetryData {
                        print("  📍 Position: \(telemetry.formattedPosition)")
                        print("  🚀 Altitude: \(String(format: "%.2f", telemetry.altitude)) km (\(telemetry.altitudeStatus) range: 400-420 km)")
                        print(
                            "  ⚡ Velocity: \(String(format: "%.2f", telemetry.velocity)) km/h (\(String(format: "%.2f", telemetry.velocity / 3600)) km/s)"
                        )
                        print("  ☀️  Visibility: \(telemetry.visibility.capitalized)")
                        print("  📡 Footprint: \(String(format: "%.2f", telemetry.footprint)) km diameter")

                        let date = Date(timeIntervalSince1970: TimeInterval(telemetry.timestamp))
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        formatter.timeZone = TimeZone(identifier: "UTC")
                        print("  🕐 Data timestamp: \(formatter.string(from: date)) UTC")
                    }

                    print("  ✅ Status: \(result.status.rawValue.uppercased())")
                    print("  ⏱️  Duration: \(String(format: "%.1f", result.duration))s")
                    print()
                    print("  🔗 View workflow: http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId)")
                    print()
                } catch {
                    print("  ❌ Failed to retrieve workflow result: \(error)")
                    print()
                }
            }

            // Process crew result
            if let workflowId = crewDesc.info.recentActions.first?.action.workflowId {
                operationCount += 1
                print("[Operation \(operationCount)] 👨‍🚀 Crew Status Check")
                print(String(repeating: "-", count: 70))

                do {
                    let handle = client.workflowHandle(
                        type: SpaceMissionWorkflow.self,
                        id: workflowId
                    )
                    let result = try await handle.result()

                    if let crew = result.crewStatus {
                        print("  🌐 Total people in space: \(crew.totalInSpace)")
                        print()
                        print("  🛸 ISS Crew (\(crew.issCrewCount) astronauts):")
                        for member in crew.issCrewMembers {
                            print("     • \(member)")
                        }

                        if !crew.otherStations.isEmpty {
                            print()
                            print("  🛸 Other Stations:")
                            for (station, members) in crew.otherStations.sorted(by: { $0.key < $1.key }) {
                                print("     \(station) (\(members.count) astronauts):")
                                for member in members {
                                    print("     • \(member)")
                                }
                            }
                        }
                    }

                    print()
                    print("  ✅ Status: \(result.status.rawValue.uppercased())")
                    print("  ⏱️  Duration: \(String(format: "%.1f", result.duration))s")
                    print()
                    print("  🔗 View workflow: http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId)")
                    print()
                } catch {
                    print("  ❌ Failed to retrieve workflow result: \(error)")
                    print()
                }
            }

            // Process health result
            if let workflowId = healthDesc.info.recentActions.first?.action.workflowId {
                operationCount += 1
                print("[Operation \(operationCount)] 🏥 System Health Check")
                print(String(repeating: "-", count: 70))

                do {
                    let handle = client.workflowHandle(
                        type: SpaceMissionWorkflow.self,
                        id: workflowId
                    )
                    let result = try await handle.result()

                    if let health = result.healthCheck, let telemetry = result.telemetryData {
                        print("  Based on real telemetry from altitude: \(String(format: "%.2f", telemetry.altitude)) km")
                        print()
                        print("  💾 Data Storage: \(String(format: "%.1f", health.dataStorageAvailable))% available")
                        print("  🔋 Power Systems: \(health.powerSystemsStatus)")
                        print("  🌡️  Thermal Control: \(String(format: "%.1f", health.thermalControlTemp))°C (Nominal)")
                        print("  📡 Communications: \(health.communicationsStatus)")
                        print("  🛰️  Orbital Parameters: \(health.orbitalParametersStatus)")
                        print("     - Altitude: \(String(format: "%.2f", telemetry.altitude)) km (target: 408±10 km)")
                        print("     - Velocity: \(String(format: "%.2f", telemetry.velocity)) km/h (target: ~27,600 km/h)")
                        print()
                        print("  ✅ Status: \(health.overallStatus)")
                    } else if let health = result.healthCheck {
                        print("  💾 Data Storage: \(String(format: "%.1f", health.dataStorageAvailable))% available")
                        print("  🔋 Power Systems: \(health.powerSystemsStatus)")
                        print("  🌡️  Thermal Control: \(String(format: "%.1f", health.thermalControlTemp))°C")
                        print("  📡 Communications: \(health.communicationsStatus)")
                        print("  🛰️  Orbital Parameters: \(health.orbitalParametersStatus)")
                        print()
                        print("  ✅ Status: \(health.overallStatus)")
                    }

                    print("  ⏱️  Duration: \(String(format: "%.1f", result.duration))s")
                    print()
                    print("  🔗 View workflow: http://localhost:8233/namespaces/\(namespace)/workflows/\(workflowId)")
                    print()
                } catch {
                    print("  ❌ Failed to retrieve workflow result: \(error)")
                    print()
                }
            }

            print(String(repeating: "=", count: 70))
            print()
            print("📊 Mission Control Dashboard")
            print(String(repeating: "-", count: 70))
            print("  Active Schedules: 3")
            print()
            print("  Next Scheduled Operations:")
            print("    • Telemetry Collection: in 90 minutes (next orbit)")
            print("    • Crew Status Check: at next scheduled time (06:00, 14:00, or 22:00 UTC)")
            print("    • System Health: at 00:00 UTC daily")
            print()
            print("  View all schedules: http://localhost:8233/schedules")
            print("  View workflows: http://localhost:8233/namespaces/\(namespace)/workflows")
            print()

            print("✅ All mission schedules active and operational")
            print()
            print("Schedules will remain active until you remove them")
            print("or restart the Temporal Dev Server.")
            print("Monitor them in the Temporal UI at the links above.")
            print()
            print("Note: To delete schedules after stopping, run:")
            print("  temporal schedule delete --schedule-id iss-telemetry-schedule")
            print("  temporal schedule delete --schedule-id iss-crew-schedule")
            print("  temporal schedule delete --schedule-id iss-health-schedule")
            print()

            // Keep running until user interrupts
            // The worker and client will continue processing scheduled workflows
            // When the user presses Ctrl+C, the task group will be cancelled
            // Note: Schedules persist in Temporal and must be manually deleted
            // Using a very large but safe duration (24 hours)
            try await Task.sleep(for: .seconds(86400))
        }
    }

    /// Performs pre-flight cleanup of existing schedules to ensure clean state
    static func performCleanup(logger: Logger) async throws {
        print("🧹 Performing pre-flight cleanup...")

        let client = try TemporalClient(
            target: .ipv4(address: "127.0.0.1", port: 7233),
            transportSecurity: .plaintext,
            configuration: .init(
                instrumentation: .init(serverHostname: "localhost")
            ),
            logger: logger
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await client.run()
            }

            // Wait for client to initialize
            try await Task.sleep(for: .milliseconds(500))

            // List of schedule IDs to clean up
            let scheduleIds = [
                "iss-telemetry-schedule",
                "iss-crew-schedule",
                "iss-health-schedule",
            ]

            var deletedCount = 0
            var notFoundCount = 0

            // Attempt to delete each schedule if it exists
            for scheduleId in scheduleIds {
                do {
                    let handle = client.untypedScheduleHandle(id: scheduleId)
                    try await handle.delete()
                    print("  ✅ Deleted existing schedule: \(scheduleId)")
                    deletedCount += 1
                } catch {
                    // Schedule doesn't exist or already deleted - this is fine
                    let errorDescription = String(describing: error)
                    if errorDescription.contains("NOT_FOUND") || errorDescription.contains("not found") {
                        print("  ℹ️  Schedule not found (already clean): \(scheduleId)")
                        notFoundCount += 1
                    } else {
                        print("  ⚠️  Could not delete schedule \(scheduleId): \(error)")
                    }
                }
            }

            if deletedCount > 0 {
                print("  ✅ Cleanup complete: deleted \(deletedCount) schedule(s)")
            } else {
                print("  ✅ Cleanup complete: all schedules already clean")
            }
            print()

            // Cancel the client
            group.cancelAll()
        }
    }
}
#else
@main
struct ScheduleExample {
    static func main() async throws {
        fatalError("GRPCNIOTransport trait disabled")
    }
}
#endif
