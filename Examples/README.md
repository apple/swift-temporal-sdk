# Swift Temporal SDK Samples

This is the set of Swift samples for the [Swift Temporal SDK](https://github.com/apple/swift-temporal-sdk).

## Usage

Prerequisites:

* Swift version: Swift 6.2+
* Local Temporal server running (can [install CLI](https://docs.temporal.io/cli#install) then
  [run a dev server](https://docs.temporal.io/cli#start-dev-server))
* A successful build of this repo. 

```bash
swift build
```

## Samples

<!-- Keep this list in alphabetical order -->
* [Async Activities](AsyncActivities) - Demonstrates parallel/concurrent activity execution using computer vision to process lemon quality control images.
* [Child Workflows](ChildWorkflows) - Demonstrates parent and child workflow orchestration through a pizza restaurant order fulfillment system with parallel and sequential child workflows.
* [Error Handling](ErrorHandling) - Shows advanced error handling patterns including retries, compensation, and failure recovery.
* [Greeting](Greeting) - Simple workflow that returns Hello.
* [Multiple Activities](MultipleActivities) - Demonstrates a workflow with multiple activities and fake database operations using Swift actors.
* [Schedule](Schedule) - Demonstrates Temporal scheduling with live NASA APIs to monitor the International Space Station, showing calendar and interval-based schedules.
* [Signals](Signals) - Demonstrates signals, queries, and updates for interacting with running workflows.
