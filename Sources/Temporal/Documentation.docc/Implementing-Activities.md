# Implementing activities

Implement activities that perform the actual work in your Temporal workflows 
with proper error handling and lifecycle management.

## Overview

Activities represent the individual units of work in your Temporal application.
They execute the actual business logic such as calling external APIs, processing
data, interacting with databases, or performing any side-effect operations that
workflows coordinate.

This article shows you how to define activities using macros, organize them in
containers, handle cancellation and timeouts, and implement proper error
handling patterns. You'll learn to build robust activities that integrate
seamlessly with your workflow orchestration.

### Define activities with the Activity macro

Use the `@Activity` macro to define activities:

```swift
import Temporal

@ActivityContainer
struct UserActivities {
    struct FindUserInput: Codable {
        var id: Int
    }
    struct FindUserOutput: Codable {
       var userName: String
    }

    var database: Database

    @Activity
    func findUser(input: FindUserInput) async throws -> FindUserOutput {
        let user = try await self.database.first(id: input.id)
        return FindUserOutput(userName: user.userName)
    }
}
```

The `@Activity` macro automatically generates activity definitions when nested
inside a type annotated with the `@ActivityContainer` macro. The container
allows you to group related activities together and provide dependencies,
such as database clients, to your activities.

### Give activities custom names

Temporal activities are identified by their name (or sometimes referred to as
"activity type"). This defaults to the unqualified method name of the activity,
but can be customized by providing a `name` parameter to the `@Activity` macro:

```swift
@Activity(name: "CustomFindUser")
func findUser(input: FindUserInput) async throws -> FindUserOutput {
    let user = try await self.database.first(id: input.id)
    return FindUserOutput(userName: user.userName)
}
```

### Registering activities with a worker

Register your activities with a ``TemporalWorker`` to make them available for
execution:

```swift
import Temporal

let worker = try TemporalWorker(
    configuration: .init(...),
    target: (...),
    transportSecurity: (...),
    activities: [UserActivities(database: database).activities.findUser],
    logger: logger
)
```

You can also register all activities inside a container at once:

```swift
import Temporal

let worker = try TemporalWorker(
    configuration: .init(...),
    target: (...),
    transportSecurity: (...),
    activities: UserActivities(database: database).allActivities,
    logger: logger
)
```

The worker processes activity tasks from the specified task queue and executes
the appropriate activity methods based on their names. When a workflow schedules
an activity execution, Temporal routes the task to a worker that has registered
an activity with the matching name.

### Access the activity's execution context

When running in an activity, the ``ActivityExecutionContext`` is available
via ``ActivityExecutionContext/current`` which is backed by a task local.
In addition to other more advanced things, this context provides:

- ``ActivityExecutionContext/Info`` - Information about the currently running activity.
- ``ActivityExecutionContext/heartbeat(details:)`` - Method to call to record an activity heartbeat.
- ``ActivityExecutionContext/cancellationReason`` - The reason for why an activity is canceled.

### Handle activity heartbeating and cancellation

In order for a non-local activity to be notified of cancellation requests, it must call
``ActivityExecutionContext/heartbeat(details:)``. It is strongly recommended that
all but the fastest executing activities call this function regularly.

Cancellation is propagated through Swift's built-in task cancellation and can 
be checked by calling `Task.isCancelled` or setting up a task cancellation handler.

An activity can be canceled for multiple reasons, some server-side and some
worker-side. Server-side cancellation reasons include workflow canceling the
activity, workflow completing, or activity timing out. On the worker side, the
activity can be canceled on worker shutdown.

```swift
@Activity
func longRunningCalculation(input: Int) async throws -> Int {
    // Get the current execution context
    let context = ActivityExecutionContext.current!

    // Use the input as our starting result
    var result = input

    while result < 5000 {
        // Simulate some long computation
        try await Task.sleep(for: .seconds(5))
        result = result * 2

        // Record a heartbeat
        context.heartbeat()
    }
    return result
}
```

In addition to obtaining cancellation information, heartbeats also support
detail data that is persisted on the server for retrieval during activity retry.
Provide the details when calling the ``ActivityExecutionContext/heartbeat(details:)``
method and retrieve them with the ``ActivityExecutionContext/Info/heartbeatDetails(as:)``
method. The above example can use this to resume from the latest computation result
when retrying the activity.

```swift
@Activity
func longRunningCalculation(input: Int) async throws -> Int {
    // Get the current execution context
    let context = ActivityExecutionContext.current!

    // Read the last recorded result if present
    let lastHeartbeatResult = try? await context.info.heartbeatDetails(as: (Int).self)

    // Either use the last recorded result or take the input
    var result = lastHeartbeatResult ?? input

    while result < 5000 {
        // Simulate some long computation
        try await Task.sleep(for: .seconds(5))
        result = result * 2

        // Record the latest result
        context.heartbeat(details: result)
    }
    return result
}
```
