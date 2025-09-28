# ``Temporal``

Build reliable, fault-tolerant distributed workflows using Swift's concurrency
features with the Temporal platform.

## Overview

The Swift Temporal SDK provides a framework for building distributed, durable
workflows and activities using Swift's modern concurrency features. Temporal
enables you to build reliable applications that recover from failures, scale
dynamically, and maintain long-running business processes with confidence.

Whether you're processing payments, orchestrating microservices, or managing
complex business workflows, the Swift Temporal SDK gives you the tools to build
production-ready applications with built-in reliability, observability, and
scalability.

Use Temporal when you need to:
- Coordinate long-running business processes across multiple services.
- Build fault-tolerant applications that survive infrastructure failures.
- Implement complex retry and error handling logic.
- Create observable workflows with rich execution history.
- Scale workflow execution across multiple workers.

## Topics

### Getting started

Learn the fundamentals of building Temporal applications.

- <doc:GettingStarted>
- <doc:Connecting-to-Temporal>

### Core development

Build activities and workflows.

- <doc:Implementing-Activities>
- <doc:Developing-Workflows>
- <doc:Workflow-Concurrency>
- <doc:Working-with-Data>

### Workflow development

Create workflows that orchestrate business logic and coordinate activities.

- ``Workflow``
- ``WorkflowOptions``
- ``WorkflowHandle``

### Activity development

Implement activities that perform the actual work in your workflows.

- ``ActivityExecutionContext``
- ``ActivityOptions``
- ``ActivityContainer``

### Configuration and deployment

Configure workers and clients for different environments.

- ``TemporalWorker/Configuration``
- ``TemporalClient/Configuration``

## See Also

- [Temporal Documentation - Complete platform documentation](https://docs.temporal.io)
- [Temporal Community - Community forum and discussions](https://community.temporal.io)
