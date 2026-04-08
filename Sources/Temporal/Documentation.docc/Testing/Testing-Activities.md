# Testing activities

Test your activities in isolation using the activity test environment
or as part of integration tests with a local test server.

## Overview

Activities contain the side-effecting business logic of your Temporal
application. The SDK provides two approaches for testing them:

1. **Unit tests** with ``withActivityTestEnvironment(info:cancellationReason:logger:_:)``
   for testing activity logic in isolation, including heartbeat and cancellation behavior.
2. **Integration tests** with ``TemporalTestServer`` for testing activities as
   part of a full workflow execution.

### Unit test activities with the test environment

Use `withActivityTestEnvironment` from the `TemporalTestKit` module to test
activities that depend on ``ActivityExecutionContext``. This sets up a mock
context without requiring a Temporal server.

```swift
import Temporal
import TemporalTestKit
import Testing

@Test
func processOrderActivity() async throws {
    let info = ActivityExecutionContext.Info(
        taskToken: Data([1, 2, 3]),
        workflowType: "OrderWorkflow",
        workflowNamespace: "default",
        activityType: "ProcessOrder",
        activityID: "1",
        isLocal: false,
        attempt: 1,
        taskQueue: "test-queue"
    )

    try await withActivityTestEnvironment(info: info) {
        let activities = OrderActivities(database: MockDatabase())
        let result = try await activities.processOrder(
            input: OrderActivities.ProcessOrderInput(orderId: "order-123")
        )
        #expect(result.status == "processed")
    }
}
```

### Test activity cancellation

Pass a `cancellationReason` to simulate cancellation scenarios and verify your
activity handles them correctly.

```swift
@Test
func activityHandlesCancellation() async throws {
    let info = ActivityExecutionContext.Info(
        taskToken: Data([1, 2, 3]),
        workflowType: "OrderWorkflow",
        workflowNamespace: "default",
        activityType: "LongRunningTask",
        activityID: "1",
        isLocal: false,
        attempt: 1,
        taskQueue: "test-queue"
    )

    try await withActivityTestEnvironment(
        info: info,
        cancellationReason: .cancelled
    ) {
        let activities = OrderActivities(database: MockDatabase())
        await #expect(throws: CancellationError.self) {
            try await activities.longRunningTask(input: ())
        }
    }
}
```

### Test activities that use heartbeats

Activities that call ``ActivityExecutionContext/heartbeat(details:)`` work
normally in the test environment. The heartbeat calls succeed without
requiring a server connection.

```swift
@Test
func activityWithHeartbeats() async throws {
    let info = ActivityExecutionContext.Info(
        taskToken: Data([1, 2, 3]),
        workflowType: "DataWorkflow",
        workflowNamespace: "default",
        activityType: "ProcessBatch",
        activityID: "1",
        isLocal: false,
        attempt: 1,
        taskQueue: "test-queue"
    )

    try await withActivityTestEnvironment(info: info) {
        let activities = DataActivities()
        let result = try await activities.processBatch(
            input: DataActivities.BatchInput(items: ["a", "b", "c"])
        )
        #expect(result.processedCount == 3)
    }
}
```

### Test activities with workflows

For end-to-end testing, use ``TemporalTestServer`` to run activities as part of
a full workflow execution. This verifies that activity inputs and outputs are
serialized correctly and that retry policies work as expected.

```swift
@Test
func workflowWithActivities() async throws {
    let server = try await TemporalTestServer()
    let client = try await TemporalClient.connect(to: server.target)
    let taskQueue = "test-queue"

    try await withTemporalWorker(
        client: client,
        taskQueue: taskQueue,
        workflows: [OrderWorkflow.self],
        activities: [OrderActivities(database: TestDatabase())]
    ) {
        let handle = try await client.startWorkflow(
            type: OrderWorkflow.self,
            options: .init(id: UUID().uuidString, taskQueue: taskQueue),
            input: OrderWorkflow.Input(orderId: "order-456")
        )
        let result = try await handle.result()
        #expect(result.status == "completed")
    }
}
```

### Test activity retry behavior

Configure retry policies in your activity options and verify they work correctly
by simulating failures.

```swift
@Test
func activityRetries() async throws {
    let server = try await TemporalTestServer()
    let client = try await TemporalClient.connect(to: server.target)
    let taskQueue = "test-queue"

    // Activity that fails on first attempt but succeeds on retry
    let activities = FlakyActivities(failUntilAttempt: 3)

    try await withTemporalWorker(
        client: client,
        taskQueue: taskQueue,
        workflows: [RetryWorkflow.self],
        activities: [activities]
    ) {
        let handle = try await client.startWorkflow(
            type: RetryWorkflow.self,
            options: .init(id: UUID().uuidString, taskQueue: taskQueue)
        )
        let result = try await handle.result()
        #expect(result == "success on attempt 3")
    }
}
```
