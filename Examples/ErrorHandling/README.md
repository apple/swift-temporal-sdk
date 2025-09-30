# Activity Error Handling Example

This sample demonstrates error handling patterns in the Swift Temporal SDK, including retry logic, error classification, and compensation patterns. It shows how to:

1. **Handle Retryable Failures**: Activities automatically retry on temporary failures like network issues
2. **Manage Non-retryable Errors**: Business logic errors that should not be retried
3. **Implement Compensation**: Cleanup logic when workflows fail after partial completion

## Activities

The example includes five activities that demonstrate different error handling patterns:

- `fetchUserData`: Fetches user data from the database (always succeeds)
- `saveWithValidation`: Validates and saves data (retries on transient errors)
- `updateUserProfile`: Updates user profile (always succeeds)
- `rollbackUserProfile`: Rolls back profile changes (compensation activity)
- `processWithCompensation`: Processes data with built-in cleanup logic

## Database State

The example uses an internal database state within the activities that simulates realistic failure patterns:
- **Fetch operations**: Always succeed (simulate reliable data retrieval)
- **Save operations**: Fail 3 times then succeed (simulate network issues)
- **Error types**: Rotate through different transient errors (outage, overload, network partition)

## Workflow Scenarios

The `ErrorHandlingWorkflow` demonstrates three different error handling scenarios:

1. **Success Scenario**: First activity succeeds, second retries 3 times then succeeds
2. **Non-Retryable Scenario**: First activity succeeds, second fails immediately with business logic error
3. **Compensation Scenario**: First two activities succeed, third fails and triggers rollback


## Running the Example

```bash
swift run ErrorHandlingExample
```

The workflow will run three scenarios demonstrating different error handling patterns:

Each scenario will display activity start/completion messages and retry attempts, resulting in output like:
```
🔄 Starting fetchUserData activity for key: user1
✅ fetchUserData completed successfully: John Doe
🔄 Starting saveWithValidation activity for data: John Doe
Database operation failed (attempt 1/3): Temporary database outage
Temporal will retry this operation.
...
✅ saveWithValidation completed successfully with key: validated_Sm9obiBEb2U=
Success Workflow Result:
Success after retries: John Doe
Saved: Data saved successfully with key: validated_Sm9obiBEb2U=
```

You can further inspect the behavior of each workflow inside the temporal UI running on localhost:8233.  