# Multiple Activities Example

This sample demonstrates how to call multiple activities from a workflow in the Swift Temporal SDK, including database operations. It shows the basic pattern of:

1. **Defining Activities**: Multiple activities that perform string transformations and database operations
2. **Creating a Workflow**: A workflow that orchestrates these activities in sequence
3. **Database Integration**: Activities that interact with a fake database client
4. **Executing the Workflow**: Running the workflow with a client and worker

## Activities

The example includes seven activities that demonstrate both simple operations and database interactions:

- `fetchUserData`: Fetches user data from the database
- `composeGreeting`: Creates a greeting message using a template from the database
- `addExclamation`: Adds exclamation marks to a string
- `addQuestion`: Adds question marks to a string
- `toUpperCase`: Converts a string to uppercase
- `addPrefix`: Adds a prefix fetched from the database
- `saveResult`: Saves the final result to the database

## Database Client

The example includes a `FakeDatabaseClient` that simulates database operations:
- `fetchData(forKey:)`: Retrieves data from the database
- `saveData(_:forKey:)`: Saves data to the database
- `deleteData(forKey:)`: Deletes data from the database

The fake database is pre-populated with sample data including user information, greeting templates, and prefixes.

## Workflow

The `MultipleActivitiesWorkflow` calls these activities in sequence, demonstrating how activities can be chained together with database operations to build more complex business logic.

## Running the Example

```bash
swift run MultipleActivitiesExample
```

The workflow will process the input "user1" through all activities, resulting in something like:
`DB_PREFIX: HELLO FROM DATABASE, JOHN DOE!!!!!!??? | Result saved with key: result_abc12345`
