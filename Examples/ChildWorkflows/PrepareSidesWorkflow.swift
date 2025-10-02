//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import Temporal

/// Child workflow that prepares side items.
///
/// Can run in parallel with pizza preparation.
@Workflow
final class PrepareSidesWorkflow {
    // MARK: - Input/Output Types

    struct SidesInput: Codable {
        let sides: [String]
    }

    // MARK: - Workflow Implementation

    func run(input: SidesInput) async throws -> String {
        // Prepare all sides
        let result = try await Workflow.executeActivity(
            PizzaActivities.Activities.PrepareSides.self,
            options: .init(startToCloseTimeout: .seconds(30)),
            input: PizzaActivities.PrepareSidesInput(sides: input.sides)
        )

        return "Sides: \(input.sides.joined(separator: ", ")) - \(result)"
    }
}
