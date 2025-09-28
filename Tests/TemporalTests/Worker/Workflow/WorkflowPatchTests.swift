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

import Foundation
import Logging
import Temporal
import TemporalTestKit
import Testing

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowPatchTests {

        // MARK: - Activities

        struct PrePatchActivity: ActivityDefinition {
            static let name: String? = "PrePatchActivity"
            func run(input: Void) async throws -> String {
                "pre-patch"
            }
        }

        struct PostPatchActivity: ActivityDefinition {
            static let name: String? = "PostPatchActivity"
            func run(input: Void) async throws -> String {
                "post-patch"
            }
        }

        // MARK: - Workflows

        @Workflow(name: "PatchWorkflow")
        final class PrePatchWorkflow {
            @WorkflowQuery
            func result(input: Void) throws -> String {
                return _result
            }
            @_WorkflowState  // This works around a compiler crash
            var _result = ""

            func run(input: Void) async throws {
                _result = try await Workflow.executeActivity(
                    PrePatchActivity.self,
                    options: .init(scheduleToCloseTimeout: .seconds(100))
                )
            }
        }

        @Workflow
        final class PatchWorkflow {
            @WorkflowQuery
            func result(input: Void) throws -> String {
                return _result
            }
            var _result = ""

            func run(input: Void) async throws {
                _result =
                    if Workflow.patch("my-patch") {
                        try await Workflow.executeActivity(
                            PostPatchActivity.self,
                            options: .init(scheduleToCloseTimeout: .seconds(100))
                        )
                    } else {
                        try await Workflow.executeActivity(PrePatchActivity.self, options: .init(scheduleToCloseTimeout: .seconds(100)))
                    }
            }
        }

        @Workflow(name: "PatchWorkflow")
        final class DeprecatedPatchWorkflow {
            @WorkflowQuery
            func result(input: Void) throws -> String {
                return _result
            }
            @_WorkflowState  // This works around a compiler crash
            var _result = ""

            func run(input: Void) async throws {
                Workflow.deprecatePatch("my-patch")
                _result = try await Workflow.executeActivity(
                    PostPatchActivity.self,
                    options: .init(scheduleToCloseTimeout: .seconds(100))
                )
            }
        }

        @Workflow(name: "PatchWorkflow")
        final class PostPatchWorkflow {
            @WorkflowQuery
            func result(input: Void) throws -> String {
                return _result
            }
            @_WorkflowState  // This works around a compiler crash
            var _result = ""

            func run(input: Void) async throws {
                _result = try await Workflow.executeActivity(
                    PostPatchActivity.self,
                    options: .init(scheduleToCloseTimeout: .seconds(100))
                )
            }
        }

        @Test
        func patch() async throws {
            let taskQueue = "tq-\(UUID().uuidString)"
            let activities: [any ActivityDefinition] = [PrePatchActivity(), PostPatchActivity()]

            let prePatchID = "wf-pre-\(UUID().uuidString)"
            try await executeWorkflow(
                PrePatchWorkflow.self,
                input: (),
                activities: activities,
                taskQueue: taskQueue,
                id: prePatchID
            ) { handle, _ in
                let prePatchResult = try await handle.query(queryType: PrePatchWorkflow.Result.self)
                #expect(prePatchResult == "pre-patch")
            }

            let patchID = "wf-patched-\(UUID().uuidString)"
            try await executeWorkflow(
                PatchWorkflow.self,
                input: (),
                activities: activities,
                taskQueue: taskQueue,
                id: patchID
            ) { handle, _ in
                let patchResult = try await handle.query(queryType: PatchWorkflow.Result.self)
                #expect(patchResult == "post-patch")

                let prePatchResult = try await handle.with(id: prePatchID).query(queryType: PatchWorkflow.Result.self)
                #expect(prePatchResult == "pre-patch")
            }

            let deprecatedPatchID = "wf-deprecated-\(UUID().uuidString)"
            try await executeWorkflow(
                DeprecatedPatchWorkflow.self,
                input: (),
                activities: activities,
                taskQueue: taskQueue,
                id: deprecatedPatchID
            ) { handle, _ in
                let deprecatedPatchResult = try await handle.query(queryType: PatchWorkflow.Result.self)
                #expect(deprecatedPatchResult == "post-patch")

                let patchResult = try await handle.with(id: patchID).query(queryType: PatchWorkflow.Result.self)
                #expect(patchResult == "post-patch")

                let prePatchError =
                    await #expect(throws: WorkflowQueryFailedError.self) {
                        _ = try await handle.with(id: prePatchID).query(queryType: PatchWorkflow.Result.self)
                    }?.message ?? ""
                #expect(prePatchError.contains("Nondeterminism"))
            }

            let postPatchID = "wf-poat-\(UUID().uuidString)"
            try await executeWorkflow(
                PostPatchWorkflow.self,
                input: (),
                activities: activities,
                taskQueue: taskQueue,
                id: postPatchID
            ) { handle, _ in
                let postPatchResult = try await handle.query(queryType: PatchWorkflow.Result.self)
                #expect(postPatchResult == "post-patch")

                let deprecatedPatchResult = try await handle.with(id: deprecatedPatchID).query(queryType: PatchWorkflow.Result.self)
                #expect(deprecatedPatchResult == "post-patch")

                let prePatchError =
                    await #expect(throws: WorkflowQueryFailedError.self) {
                        try await handle.with(id: prePatchID).query(queryType: PatchWorkflow.Result.self)
                    }?.message ?? ""
                #expect(prePatchError.contains("Nondeterminism"))

                let patchError =
                    await #expect(throws: WorkflowQueryFailedError.self) {
                        try await handle.with(id: patchID).query(queryType: PatchWorkflow.Result.self)
                    }?.message ?? ""
                #expect(patchError.contains("Nondeterminism"))
            }
        }
    }
}
