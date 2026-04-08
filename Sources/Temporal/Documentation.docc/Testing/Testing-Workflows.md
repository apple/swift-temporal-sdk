# Testing workflows

Verify your workflow logic using integration tests with a local test server
and replay tests with recorded histories.

## Overview

Temporal workflows are deterministic and replay-safe, which makes them
straightforward to test. The SDK provides two testing approaches:

1. **Integration tests** with ``TemporalTestServer`` that run workflows against
   a local Temporal server.
2. **Replay tests** with ``WorkflowReplayer`` that verify workflow code changes
   are compatible with recorded execution histories.

This article walks through both approaches and shows how to test signals,
queries, updates, and time-dependent behavior.

### Integration tests with a test server

Use ``TemporalTestServer`` from the `TemporalTestKit` module to spin up a local
Temporal server, start a worker, and drive your workflow through its lifecycle.

```swift
import Temporal
import TemporalTestKit
import Testing

@Test
func greetingWorkflow() async throws {
    let server = try await TemporalTestServer()
    let client = try await TemporalClient.connect(to: server.target)
    let taskQueue = "test-queue"

    try await withTemporalWorker(
        client: client,
        taskQueue: taskQueue,
        workflows: [GreetingWorkflow.self],
        activities: [GreetingActivities()]
    ) {
        let handle = try await client.startWorkflow(
            type: GreetingWorkflow.self,
            options: .init(id: UUID().uuidString, taskQueue: taskQueue),
            input: "World"
        )
        let result = try await handle.result()
        #expect(result == "Hello, World!")
    }
}
```

The test server starts automatically and shuts down when the test completes.

### Test signals, queries, and updates

Send signals and queries to a running workflow to verify handler behavior.

```swift
@Test
func signalAndQuery() async throws {
    let server = try await TemporalTestServer()
    let client = try await TemporalClient.connect(to: server.target)
    let taskQueue = "test-queue"

    try await withTemporalWorker(
        client: client,
        taskQueue: taskQueue,
        workflows: [OrderWorkflow.self],
        activities: [OrderActivities()]
    ) {
        let handle = try await client.startWorkflow(
            type: OrderWorkflow.self,
            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
        )

        // Send a signal
        try await handle.signal(
            signalType: OrderWorkflow.Approve.self
        )

        // Query the workflow state
        let status = try await handle.query(
            queryType: OrderWorkflow.GetStatus.self
        )
        #expect(status == "approved")

        // Execute an update
        let result = try await handle.executeUpdate(
            updateType: OrderWorkflow.SetPriority.self,
            input: "expedited"
        )
        #expect(result == "expedited")

        let _ = try await handle.result()
    }
}
```

### Test time-dependent behavior

Use the time-skipping test server to accelerate workflows that sleep or use
timers. The time-skipping interceptor automatically advances time when the
workflow is idle.

```swift
@Test
func timeSkippingWorkflow() async throws {
    let server = try await TemporalTestServer(timeSkipping: true)
    let client = try await TemporalClient.connect(
        to: server.target,
        interceptors: [TimeSkippingClientInterceptor(server)]
    )
    let taskQueue = "test-queue"

    try await withTemporalWorker(
        client: client,
        taskQueue: taskQueue,
        workflows: [ReminderWorkflow.self]
    ) {
        let handle = try await client.startWorkflow(
            type: ReminderWorkflow.self,
            options: .init(id: UUID().uuidString, taskQueue: taskQueue),
            input: "Check status"
        )

        // This workflow sleeps for 24 hours, but the time-skipping server
        // advances time automatically so the test completes instantly.
        let result = try await handle.result()
        #expect(result == "Reminder sent: Check status")
    }
}
```

### Replay tests with WorkflowReplayer

Use ``WorkflowReplayer`` to test that workflow code changes are compatible with
existing execution histories. This catches non-deterministic changes before they
reach production.

Export a workflow history from the Temporal CLI:

```bash
temporal workflow show --workflow-id my-workflow-123 --output json > history.json
```

Then replay it in a test:

```swift
@Test
func replayCompatibility() async throws {
    var config = WorkflowReplayer.Configuration()
    config.workflows.append(MyWorkflow.self)

    let replayer = WorkflowReplayer(configuration: config)

    let json = try String(contentsOfFile: "history.json")
    let history = try WorkflowHistory.fromJSON(
        workflowID: "my-workflow-123",
        json: json
    )

    let result = try await replayer.replayWorkflow(history: history)
    #expect(result.succeeded)
}
```

If the workflow code has changed in a non-deterministic way (for example,
reordering activity calls or removing a timer), the replay fails and the
result contains the error.

### Test update validators

When using `@WorkflowUpdate(validator:)`, test that the validator correctly
accepts valid input and rejects invalid input.

```swift
@Test
func updateValidatorRejects() async throws {
    let server = try await TemporalTestServer()
    let client = try await TemporalClient.connect(to: server.target)
    let taskQueue = "test-queue"

    try await withTemporalWorker(
        client: client,
        taskQueue: taskQueue,
        workflows: [OrderWorkflow.self]
    ) {
        let handle = try await client.startWorkflow(
            type: OrderWorkflow.self,
            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
        )

        // Invalid input should be rejected by the validator
        await #expect(throws: (any Error).self) {
            try await handle.executeUpdate(
                updateType: OrderWorkflow.SetPriority.self,
                input: ""
            )
        }

        // Valid input should succeed
        let result = try await handle.executeUpdate(
            updateType: OrderWorkflow.SetPriority.self,
            input: "high"
        )
        #expect(result == "high")
    }
}
```
