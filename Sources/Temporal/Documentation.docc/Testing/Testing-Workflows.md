# Testing workflows

Run workflows against a local test server, and catch non-deterministic code
changes with replay tests before they reach production.

## Overview

Temporal workflows are deterministic and replay-safe, so the same input
history produces the same result. This property makes workflows especially
testable, but it also means that innocent-looking code changes can break
replay in production.

You can run workflows against a local test server; test signals, queries,
and updates; skip time for long-running workflows; and verify that code
changes stay deterministic with replay testing. There are two main approaches:

1. **Integration tests** with `TemporalTestServer` that run workflows against
   a local Temporal server.
2. **Replay tests** with ``WorkflowReplayer`` that verify workflow code changes
   are compatible with recorded execution histories.

### Integration testing a workflow

Apply the `.temporalTestServer` test trait to start a local Temporal server.
Use `TemporalTestServer.withConnectedWorker` and
`TemporalTestServer.withConnectedClient` to set up a worker and client
connected to the test server:

```swift
import Logging
import Temporal
import TemporalTestKit
import Testing

@Suite(.temporalTestServer)
struct GreetingWorkflowTests {
    @Test
    func greetingReturnsHello() async throws {
        let testServer = TemporalTestServer.testServer!
        let taskQueue = "test-\(UUID())"
        let logger = Logger(label: "test")

        let config = TemporalWorker.Configuration(
            namespace: "default",
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        try await testServer.withConnectedWorker(
            configuration: config,
            activities: GreetingActivities().allActivities,
            workflows: [GreetingWorkflow.self]
        ) { _ in
            try await testServer.withConnectedClient(
                logger: logger
            ) { client in
                let handle = try await client.startWorkflow(
                    type: GreetingWorkflow.self,
                    options: .init(
                        id: "wf-\(UUID())",
                        taskQueue: taskQueue
                    ),
                    input: "World"
                )
                let result = try await handle.result()
                #expect(result == "Hello, World!")
            }
        }
    }
}
```

> Important: The `.temporalTestServer` trait manages the server lifecycle.
> It starts before your tests run and shuts down when they complete.

### Testing signals, queries, and updates

Send signals, run queries, and execute updates on a running workflow to verify
handler behavior. For how to define these handlers, see
<doc:Developing-Workflows>.

The following workflow defines signal, query, and update handlers:

```swift
@Workflow
struct CounterWorkflow {
    private var count = 0

    mutating func run(
        context: WorkflowContext<Self>,
        input: Void
    ) async throws -> Int {
        try await context.condition { $0.count >= 3 }
        return count
    }

    @WorkflowSignal
    mutating func increment(input: Void) {
        count += 1
    }

    @WorkflowQuery
    func currentCount(input: Void) -> Int {
        count
    }

    @WorkflowUpdate
    mutating func setCount(input: Int) -> Int {
        count = input
        return count
    }
}
```

Test each handler type through the workflow handle. The worker and client
setup is the same as the integration test above. The test body sends signals,
runs a query, and executes an update:

```swift
let handle = try await client.startWorkflow(
    type: CounterWorkflow.self,
    options: .init(id: "wf-\(UUID())", taskQueue: taskQueue)
)

try await handle.signal(signalType: CounterWorkflow.Increment.self)
try await handle.signal(signalType: CounterWorkflow.Increment.self)

let count = try await handle.query(
    queryType: CounterWorkflow.CurrentCount.self
)
#expect(count == 2)

// Set the counter directly via an update
let updated = try await handle.executeUpdate(
    updateType: CounterWorkflow.SetCount.self,
    input: 10
)
#expect(updated == 10)

let result = try await handle.result()
#expect(result == 10)
```

### Testing time-dependent workflows

Use the `.temporalTimeSkippingTestServer` test trait to test workflows that
sleep or use timers. The time-skipping server fast-forwards time when the
workflow is idle, so tests complete in seconds regardless of the sleep
duration:

```swift
@Workflow
struct DelayedGreetingWorkflow {
    mutating func run(
        context: WorkflowContext<Self>,
        input: String
    ) async throws -> String {
        try await context.sleep(for: .seconds(86_400))
        return "Hello, \(input)!"
    }
}
```

```swift
@Suite(.temporalTimeSkippingTestServer)
struct TimeSkippingTests {
    @Test
    func delayedGreetingCompletesQuickly() async throws {
        let testServer = TemporalTestServer.timeSkippingTestServer!
        let taskQueue = "test-\(UUID())"
        let logger = Logger(label: "test")

        let config = TemporalWorker.Configuration(
            namespace: "default",
            taskQueue: taskQueue,
            instrumentation: .init(serverHostname: "localhost")
        )

        try await testServer.withConnectedWorker(
            configuration: config,
            workflows: [DelayedGreetingWorkflow.self]
        ) { _ in
            try await testServer.withConnectedClient(
                logger: logger
            ) { client in
                let start = ContinuousClock.now
                let handle = try await client.startWorkflow(
                    type: DelayedGreetingWorkflow.self,
                    options: .init(
                        id: "wf-\(UUID())",
                        taskQueue: taskQueue
                    ),
                    input: "World"
                )
                let result = try await handle.result()
                #expect(result == "Hello, World!")

                let elapsed = ContinuousClock.now - start
                #expect(elapsed < .seconds(30))
            }
        }
    }
}
```

> Tip: `TemporalTestServer.withConnectedClient` installs the
> time-skipping interceptor for you.

### Replay testing with WorkflowReplayer

``WorkflowReplayer`` replays a workflow against a recorded history, so you
can verify that code changes stay deterministic.

> Important: A workflow must produce the same sequence of commands when replayed
> against its recorded history. Adding, removing, or reordering activities,
> timers, or child workflows breaks replay.

Common causes of replay failure include reordering activity calls, adding or
changing timer durations, branching on `Date()` or `UUID()` instead of
workflow context APIs, and non-deterministic collection order (for example,
iterating a dictionary).

Export a workflow history from the Temporal CLI:

```bash
temporal workflow show --workflow-id my-workflow --output json > history.json
```

Then replay it in a test:

```swift
@Test
func replayCompatibility() async throws {
    var config = WorkflowReplayer.Configuration()
    config.workflows.append(GreetingWorkflow.self)

    let replayer = WorkflowReplayer(configuration: config)

    let jsonData = try Data(
        contentsOf: URL(fileURLWithPath: "history.json")
    )
    let history = try WorkflowHistory.fromJSON(
        workflowID: "my-workflow",
        jsonData: jsonData
    )

    let result = try await replayer.replayWorkflow(
        history: history,
        throwOnReplayFailure: false
    )
    #expect(result.replayFailure == nil)
}
```

You can also skip the CLI export by calling
``WorkflowHandle/fetchHistory(waitNewEvent:eventFilterType:skipArchival:callOptions:)``
on a completed workflow handle and replaying the result directly in your test.
