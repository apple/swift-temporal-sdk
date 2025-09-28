//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Cassandra Client project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

/// A seeded deterministic random number generator for workflows that ensures consistent replay behavior.
///
/// The workflow random number generator provides deterministic randomness within workflow execution contexts.
/// It uses a seeded generator that produces identical sequences during workflow replay, maintaining
/// deterministic behavior while providing random values for workflow operations.
///
/// ## Usage Example
///
/// ```swift
/// // Within a workflow implementation
/// let randomValue = UInt64.random(in: 1...100, using: &workflowContext.randomNumberGenerator)
/// let shouldExecute = Bool.random(using: &workflowContext.randomNumberGenerator)
/// ```
public struct WorkflowRandomNumberGenerator: RandomNumberGenerator, Sendable {
    /// The workflow state machine storage that provides deterministic random number generation.
    ///
    /// The state machine coordinates random number generation to ensure deterministic behavior
    /// across workflow executions and replays.
    private let stateMachine: WorkflowStateMachineStorage

    /// Creates a new workflow random number generator with the specified state machine.
    ///
    /// - Parameter stateMachine: The workflow state machine storage that coordinates
    ///   deterministic random number generation within the workflow execution context.
    init(stateMachine: WorkflowStateMachineStorage) {
        self.stateMachine = stateMachine
    }

    /// Generates the next random number in the deterministic sequence.
    ///
    /// This method produces the next 64-bit unsigned integer in the deterministic random sequence.
    /// The value is generated using the workflow's seeded random number generator, ensuring
    /// consistent behavior across workflow replays.
    ///
    /// - Returns: A 64-bit unsigned integer from the deterministic random sequence.
    public mutating func next() -> UInt64 {
        self.stateMachine.generateNextRandomNumber()
    }
}
