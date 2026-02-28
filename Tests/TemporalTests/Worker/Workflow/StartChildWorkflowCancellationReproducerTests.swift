import Foundation
import Temporal
import TemporalTestKit
import Testing
import Logging

extension TestServerDependentTests {
    struct StartChildWorkflowCancellationReproducerTests {
        @Workflow
        final class ChildWorkflow {
            struct Input: Codable {
                let id: Int
            }

            func run(input: Input) async throws {
                try await Workflow.sleep(for: .seconds(3600))
            }
        }

        @Workflow
        final class ParentWorkflow {
            func run(input: Void) async throws {
                let logger = Workflow.logger
                var ids: [Int] = []
                ids.reserveCapacity(150)
                for index in 0..<150 {
                    ids.append(index)
                }

                var handles: [ChildWorkflowHandle<ChildWorkflow>] = []
                handles.reserveCapacity(ids.count)

                _ = Workflow.patch("starting child-workflows ...")

                for id in ids {
                    do {
                        let handle = try await Workflow.startChildWorkflow(ChildWorkflow.self, input: .init(id: id))
                        handles.append(handle)
                    } catch is CanceledError {
                        logger.info("Workflow cancelled skipping start of the other child workflows.")
                        break
                    } catch {
                        logger.info("Starting child workflow failed: \(error)")
                        throw error
                    }
                }

                _ = Workflow.patch("started child-workflows")

                var successfulWorkflows = 0
                var cancelledWorkflows = 0
                var erroneousWorkflows = 0

                for handle in handles {
                    do {
                        try await handle.result()
                        successfulWorkflows += 1
                    } catch let error as ChildWorkflowError where error.cause is CanceledError {
                        cancelledWorkflows += 1
                    } catch {
                        erroneousWorkflows += 1
                    }
                }

                logger.info("Workflow completed", metadata: [
                    "success": "\(successfulWorkflows)",
                    "cancelled": "\(cancelledWorkflows)",
                    "errors": "\(erroneousWorkflows)"
                ])

                if Task.isCancelled {
                    throw CanceledError(message: "Workflow was cancelled!")
                }
            }
        }

        @Test("Cancellation Test")
        func cancellationTest() async throws {
            try await withTestWorkerAndClient(workflows: [ChildWorkflow.self, ParentWorkflow.self]) { taskQueue, client in
                while true {
                    let handle = try await client.startWorkflow(
                        type: ParentWorkflow.self,
                        options: .init(id: UUID().uuidString.lowercased(), taskQueue: taskQueue)
                    )

                    // let's spawn a few child workflows
                    try await _Concurrency.Task.sleep(for: .seconds(3))

                    try await handle.cancel()

                    let error = try await #require(throws: WorkflowFailedError.self) {
                        try await handle.result()
                    }

                    let events = try await handle.fetchHistoryEvents()
                    #expect(error.cause is CanceledError)
                    if (error.description.contains("TMPRL1100")) {
                        Issue.record(error) // set break-point here to inspect `events` from above
                        break
                    } else if error.cause is CanceledError {
                        print("It worked")  // set break-point here to inspect `events` from above
                    } else {
                        Issue.record(error, "Unexpected error")  // set break-point here to inspect `events` from above
                        break
                    }
                }
            }
        }
    }
}
