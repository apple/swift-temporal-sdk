# Signals, Queries, and Updates

Demonstrates Temporal's message passing capabilities through an order processing workflow.

## Features

**Signals** - Asynchronous, no return value
- `pause()` - Pause workflow execution
- `resume()` - Resume paused workflow
- `cancel()` - Cancel workflow

**Queries** - Synchronous, read-only
- `getStatus()` - Get current workflow state and progress

**Updates** - Synchronous, mutates and returns
- `setPriority()` - Change priority with validation

## Usage

Start Temporal server:
```bash
temporal server start-dev
```

Run the example:
```bash
cd Examples/Signals
swift run SignalExample
```

The example demonstrates:
1. Start workflow and query initial status
2. Update priority to "expedited"
3. Pause workflow with signal
4. Query to confirm paused state
5. Resume workflow with signal
6. Query to confirm resumed state
7. Workflow completes

## Key Patterns

**Waiting for signals with `Workflow.condition`:**
```swift
try await Workflow.condition { !self.isPaused || self.isCancelled }
```

**Update validation:**
```swift
@WorkflowUpdate
func setPriority(input: SetPriorityInput) async throws -> String {
    guard validPriorities.contains(input.priority) else {
        throw ApplicationError(...)
    }
    priority = input.priority
    return "Priority changed"
}
```

View workflow in Temporal UI: `http://localhost:8233`
