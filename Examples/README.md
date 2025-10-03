# Swift Temporal SDK Samples

This is the set of Swift samples for the [Swift Temporal SDK](https://github.com/apple/swift-temporal-sdk).

## Usage

Prerequisites:

* Swift version: Swift 6.2+
* Local Temporal server running (can [install CLI](https://docs.temporal.io/cli#install) then
  [run a dev server](https://docs.temporal.io/cli#start-dev-server))

### Building Examples

The examples are organized as a separate Swift package that depends on the main SDK. To build and run examples:

```bash
# From the Examples directory
cd Examples
swift build --product <ExampleName>

# Or from the repository root
swift build --package-path Examples --product <ExampleName>
```

### Running Examples

After building, run an example:

```bash
# From Examples directory
swift run <ExampleName>

# Or from repository root
swift run --package-path Examples <ExampleName>
```

For example, to build and run the Greeting example:

```bash
cd Examples
swift build --product GreetingExample
swift run GreetingExample
```

## Samples

<!-- Keep this list in alphabetical order -->
* [Async Activities](AsyncActivities) - Demonstrates parallel/concurrent activity execution using NYC's Open Data API to process film permits.
* [Child Workflows](ChildWorkflows) - Demonstrates parent and child workflow orchestration through a pizza restaurant order fulfillment system with parallel and sequential child workflows.
* [Error Handling](ErrorHandling) - Shows advanced error handling patterns including retries, compensation, and failure recovery.
* [Greeting](Greeting) - Simple workflow that returns Hello.
* [Multiple Activities](MultipleActivities) - Demonstrates a workflow with multiple activities and fake database operations using Swift actors.
* [Schedule](Schedule) - Demonstrates Temporal scheduling with live NASA APIs to monitor the International Space Station, showing calendar and interval-based schedules.
* [Signals](Signals) - Demonstrates signals, queries, and updates for interacting with running workflows.
