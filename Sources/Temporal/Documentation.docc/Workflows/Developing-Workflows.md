# Developing workflows

Create durable, deterministic workflows that orchestrate business logic and
coordinate activities.

## Overview

Workflows are the heart of your Temporal application. They define the business
logic that coordinates activities, handles failures, and maintains state across
long-running processes. Workflows must be deterministic to ensure reliable
replay and recovery.

This article shows you how to define workflows, coordinate activities, handle
signals and queries, and implement complex orchestration patterns. You'll learn
to build workflows that survive failures and scale across distributed systems.

### Define a workflow with the Workflow macro

Use the `@Workflow` macro on a `final class` to create a ``WorkflowDefinition``.
The main entry point for a workflow is the `run` method, which returns the
workflow result. Errors thrown from the `run` method are treated as to workflow
failures.

The following example illustrates a register user workflow that accepts a user
name and returns a user ID when complete:

```swift
import Temporal

@Workflow
final class RegisterUserWorkflow {
    struct Input: Codable {
        var userName: String
    }
    struct Output: Codable {
        var userID: String
    }

    func run(input: Input) async throws -> Output {
        // Validate that the user name is not empty
        guard !input.userName.isEmpty else {
            throw ApplicationError(message: "Empty user name")
        }
        
        // Check if a user with the name already exists
        let existingUserID = try await Workflow.executeActivity(
            UserActivities.Activities.FindUserByName.self,
            options: ActivityOptions(
                startToCloseTimeout: .minutes(5)
            ),
            input: FindUserByNameInput(
                userName: input.userName
            )
        )

        // Validate that the user doesn't exist already
        guard existingUserID == nil else {
            throw ApplicationError(message: "User already exists")
        }

        // Register the new user
        let userID = try await Workflow.executeActivity(
            UserActivities.Activities.RegisterUser.self,
            options: ActivityOptions(
                startToCloseTimeout: .minutes(5)
            ),
            input: RegisterUserInput(
                userName: input.userName
            )
        )

        return Output(userID: userID)
    }
}
```

#### Best practices for workflow definitions

Workflows should define custom input and output types rather than using basic
types. This allows adding optional fields to input or output structures without
breaking existing workflows.

#### Customizing workflow names

By default, workflows use their class name as the workflow type. You can
customize this by providing a `name` parameter in the `@Workflow` macro:

```swift
@Workflow(name: "CustomRegisterUserWorkflow")
final class RegisterUserWorkflow {
    // Implementation
}
```

#### Initializing state

Define an optional `init(input:)` initializer to set up the workflow state from
input parameters, eliminating the need for optional properties or
force-unwrapping.

```swift
@Workflow
final class RegisterUserWorkflow {
    struct Input: Codable {
        var userName: String
    }
    struct Output: Codable {
        var userID: String
    }

    private let userName: String

    init(input: Input) {
        self.userName = input.userName
    }

    func run(input: Input) async throws -> Output {
        // Workflow implementation
    }
}
```

### Defining signal, query, and update handlers

Use the `@WorkflowSignal`, `@WorkflowQuery`, and `@WorkflowUpdate` macros
inside a type annotated with the `@Workflow` macro to define those respective
handlers.

#### Signal handlers

Signal handlers allow external systems to send information to running workflows.
They're ideal for handling approvals, cancellations, or status updates.

The following example is an enhanced version of the user registration workflow
that waits for approval:

```swift
@Workflow
final class RegisterUserWorkflow {
    struct Input: Codable {
        var userName: String
    }
    
    struct Output: Codable {
        var userID: String
        var approverID: String
    }
    
    // Signal input type
    struct ApprovalSignal: Codable {
        var approverID: String
    }
    
    private var approverID: String?
    
    func run(input: Input) async throws -> Output {
        // Validate input
        guard !input.userName.isEmpty else {
            throw ApplicationError(message: "Empty user name")
        }
        
        // Check if user already exists
        let existingUserID = try await Workflow.executeActivity(
            UserActivities.Activities.FindUserByName.self,
            options: ActivityOptions(startToCloseTimeout: .minutes(5)),
            input: FindUserByNameInput(userName: input.userName)
        )
        
        guard existingUserID == nil else {
            throw ApplicationError(message: "User already exists")
        }
        
        // Wait for approval
        try await Workflow.condition { self.approverID != nil }
        
        // Register the approved user
        let userID = try await Workflow.executeActivity(
            UserActivities.Activities.RegisterUser.self,
            options: ActivityOptions(startToCloseTimeout: .minutes(5)),
            input: RegisterUserInput(userName: input.userName, email: input.email)
        )
        
        return Output(userID: userID, approverID: self.approverID!)
    }
    
    @WorkflowSignal
    func approveRegistration(input: ApprovalSignal) async throws {
        self.approverID = input.approverID
    }
}
```

Signal handlers can be asynchronous and throw errors, but cannot return values.
Follow the same best practice of using custom input types for signal handlers
as you do for workflows to support backward compatibility.

By default the signal name is the unqualified capitalized method name.
You can customize the signal name using the `name` parameter, for example:

```swift
@WorkflowSignal(name: "CustomApproveRegistration")
```

#### Query handlers

Queries allow external systems to retrieve information synchronously from running workflows.
They're useful for getting the current state of a workflow without modifying it.

The following example illustrates how to add a query to check the registration status:

```swift
@Workflow
final class RegisterUserWorkflow {
    // ... previous structs and properties ...
    
    enum RegistrationState: String, Codable {
        case waitingForApproval = "waiting_for_approval"
        case approved = "approved"
        case registered = "registered"
    }
    
    struct StateQuery: Codable {
        // Empty input for this query
    }
    
    struct StateResponse: Codable {
        var state: RegistrationState
        var approverID: String?
    }
    
    private var currentState: RegistrationState = .waitingForApproval
    
    func run(input: Input) async throws -> Output {
        self.currentState = .waitingForApproval
        
        // ... validation and user existence check ...

        // Wait for approval
        try await Workflow.condition { self.approverID != nil }
        
        self.currentState = .approved
        
        // Register the user
        let userID = try await Workflow.executeActivity(
            UserActivities.Activities.RegisterUser.self,
            options: ActivityOptions(startToCloseTimeout: .minutes(5)),
            input: RegisterUserInput(userName: input.userName, email: input.email)
        )
        
        self.currentState = .registered
        return Output(userID: userID, approverID: self.approverID!)
    }
    
    @WorkflowQuery
    func getRegistrationState(input: StateQuery) throws -> StateResponse {
        return StateResponse(
            state: currentState,
            approverID: approverID,
        )
    }
    
    // ... signal handler ...
}
```

Query handlers must be synchronous, and can throw errors. They can't perform
activities or other asynchronous operations. Use custom input and output types
for queries to maintain backward compatibility.

By default, the signal name is the unqualified capitalized method name.
You can customize the query name using the `name` parameter, for example:

```swift
@WorkflowQuery(name: "CustomGetRegistrationState")
```

#### Update handlers

Updates combine aspects of both signals and queries - they can modify a workflow's
state and return values asynchronously.

The following example illustrates how to add an update handler to modify the
user registration details:

```swift
@Workflow
final class RegisterUserWorkflow {
    // ... previous structs and properties ...
    
    struct UpdateUserNameInput: Codable {
        var userName: String
    }
    
    struct UpdateUserNameOutput: Codable {
        var success: Bool
    }
    
    private var currentState: RegistrationState = .waitingForApproval
    private var userName: String

    init(input: Input) {
        self.userName = input.userName
    }
    
    func run(input: Input) async throws -> Output {        
        // ... rest of workflow logic ...
    }
    
    @WorkflowUpdate
    func updateUserName(input: UpdateUserNameInput) async throws -> UpdateUserNameOutput {
        // Can only update details while waiting for approval
        guard currentState == .waitingForApproval else {
            return UpdateUserDetailsOutput(
                success: false
            )
        }

        self.userName = input.userName

        return UpdateUserDetailsOutput(
            success: true
        )
    }
    
    // ... other handlers ...
}
```

Update handlers can be asynchronous and throw errors, and can return
values. Unlike queries, updates can modify workflow state and execute
activities. Use custom input and output types for updates to maintain backward
compatibility.

By default the update name is the unqualified
capitalized method name. You can customize the update name using the
`name` parameter, for example:

```swidt
@WorkflowUpdate(name: "CustomUpdateUserName")
```
