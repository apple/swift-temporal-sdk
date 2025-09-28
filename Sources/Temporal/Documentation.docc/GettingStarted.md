# Getting started

Build your first Temporal workflow and activity.

## Overview

This guide walks you through creating a simple Temporal workflow consisting
of a single activity, from installation to running your first workflow locally.
This article shows you how to create an activity, define a workflow that calls it,
set up a worker, and execute the workflow.

## Add the dependency

Add the Swift Temporal SDK to your package dependencies. Use the command

```sh
swift package add-dependency \
    https://github.com/apple/swift-temporal-sdk \
    --from 0.1.0
```

Or manually update your project's Package.swift to include the SDK as a dependency:

```swift
dependencies: [
    .package(
        url: "https://github.com/apple/swift-temporal-sdk",
        from: "0.1.0"
    )
]
```

## Set up a local Temporal server

Install the Temporal CLI by visiting https://temporal.io/setup/install-temporal-cli
and following the installation instructions for your platform. After the CLI is installed,
start a development server:

```sh
# Start development server
temporal server start-dev
```

The development server runs at `localhost:7233`, and hosts a Web UI at
`http://localhost:8233`.

## Create your first workflow

### Define the activity

Activities are the units of work within a workflow, and define the logic that performs the work in your application.
Create a simple greeting activity:

```swift
import Temporal

@ActivityContainer
struct GreetingActivities {
    @Activity
    func sayHello(input: String) -> String {
        "Hello, \(input)!"
    }
}
```

### Define the workflow

Workflows orchestrate activities and contain your business logic for coordinating them.
Create a workflow that calls the activity and returns the generated greeting:

```swift
@Workflow
final class GreetingWorkflow {
    func run(input: String) async throws -> String {
        let greeting = try await Workflow.executeActivity(
            GreetingActivities.Activities.sayHello.self,
            options: ActivityOptions(
                startToCloseTimeout: .seconds(30)
            ),
            input: input
        )
        
        return greeting
    }
}
```

### Start a worker and client

Create an application that starts a worker with the workflow and activity, then
execute the workflow:

```swift
import Foundation
import GRPCNIOTransportHTTP2Posix
import Logging
import Temporal

@main
struct GreetingApplication {
    static func main() async throws {
        let logger = Logger(label: "TemporalWorker")

        let namespace = "default"
        let taskQueue = "greeting-queue"

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
            activityContainers: GreetingActivities(),
            activities: [],
            workflows: [GreetingWorkflow.self],
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

        try await withThrowingTaskGroup { group in
            group.addTask {
                try await worker.run()
            }

            group.addTask {
                try await client.run()
            }

            // Wait for the worker and client to run
            try await Task.sleep(for: .seconds(1))

            print("Executing workflow")
            let greeting = try await client.executeWorkflow(
                type: GreetingWorkflow.self,
                options: .init(id: UUID().uuidString, taskQueue: taskQueue),
                input: "Max"
            )

            print(greeting)

            // Cancel the client and worker
            group.cancelAll()
        }
    }
}
```

## Run your application

When you run your application, you should see output similar to:

```
Executing workflow
Hello, Max!
```

The Temporal Web UI at `http://localhost:8233` shows your workflow execution
with detailed logs and execution history.
