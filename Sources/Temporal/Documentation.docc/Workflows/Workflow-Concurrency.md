# How workflows leverage Swift Concurrency

Build deterministic workflows using Swift's async/await and Structured
Concurrency primitives.

## Overview

Temporal workflows integrate seamlessly with Swift Concurrency, allowing you to
use familiar async/await syntax and Structured Concurrency patterns. The 
framework ensures deterministic execution through a specialized task executor
that maintains consistent ordering across replays and retries.

Workflows can safely use Swift's concurrency primitives, such as `async let`,
`withTaskGroup`, and `withThrowingTaskGroup`, while maintaining the deterministic
execution guarantees required by Temporal. This enables you to write concurrent
workflow logic that remains predictable and testable.

### Deterministic execution guarantees

Workflows run on a specialized task executor that ensures consistent execution
order across different runs. This executor processes tasks sequentially by task
ID, guaranteeing that concurrent operations within your workflow execute in the
same order during replay.

The executor buffers enqueued jobs and runs them in a deterministic sequence.
When a task finishes running, the executor checks if that task has enqueued
another job and runs it immediately. This ensures a single task runs until it 
reaches a real suspension point before the executor picks up the next job. This
approach also ensures that Structured Concurrency patterns like task groups produce
identical results across workflow replays.

### Use Structured Concurrency patterns

Workflows support Swift's Structured Concurrency patterns, including task groups
and async let bindings. These patterns maintain deterministic execution while
enabling concurrent operations.

Here's an example using a task group to run two child tasks concurrently:

```swift
@Workflow
final class DataProcessingWorkflow {
    func run(input: Void) async throws -> String {
        // Use task group to run two operations concurrently
        return try await withTaskGroup(of: String.self) { group in
            // First child task - validate data
            group.addTask {
                return "First"
            }
            
            // Second child task - fetch configuration
            group.addTask {
                return "Second"
            }
            
            // Collect results from both tasks
            var result = [String]()
            for try await string in group {
                result.append(string)
            }

            // This is guaranteed to return "First Second"
            return result.joined(separator: " ")
        }
    }
}
```

The workflow executor ensures that even though tasks run concurrently, they
execute in a consistent order during replay. The first task added to the group
is run first, followed by the second task, maintaining deterministic behavior.

### Use safe APIs for deterministic execution

Workflows must maintain deterministic behavior across replays. Use only these
APIs inside your workflows:

**Safe to use:**
- `async let` bindings for concurrent operations.
- Task group APIs (`withTaskGroup`, `withThrowingTaskGroup`, discarding variants).
- All ``Workflow`` APIs for activities, timers, conditions, and more.
- Swift's standard Task cancellation primitives.

**Avoid these APIs:**
- `Task.detached` - Instead use Structured Concurrency alternatives.
- Actor isolation - Introduces potential executor hops.
- `Task.sleep` or `Clock.sleep` - Instead, use ``Workflow/sleep(for:summary:)``.
- Direct I/O operations - Instead, use activities for any non-deterministic code.
- Non-deterministic APIs like `RandomNumberGenerator` - Instead, use
``Workflow/randomNumberGenerator``.

### Handle cancellation properly

Workflows support Swift's standard cancellation primitives, enabling graceful
shutdown and cleanup. Use `Task.isCancelled`, `withTaskCancellationHandler`, and
other cancellation APIs as you would in regular Swift code.

When a workflow is cancelled, many ``Workflow`` operations throw
`CancellationError`, allowing your workflow to detect cancellation and perform
cleanup. Cancellation propagates through structured concurrency patterns, such as
task groups, ensuring that all child tasks are properly cancelled when the workflow
is cancelled.

