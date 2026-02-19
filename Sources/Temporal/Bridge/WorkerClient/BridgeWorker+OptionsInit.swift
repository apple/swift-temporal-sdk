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

import Bridge

extension BridgeWorker {
    static func withWorkerOptions<T>(
        namespace: String,
        taskQueue: String,
        identity: String,
        hasActivities: Bool,
        hasWorkflows: Bool,
        versioningStrategy: TemporalWorker.Configuration.VersioningStrategy,
        tuner: TemporalCoreTunerHolder,
        maxCachedWorkflows: UInt32,
        stickyQueueTimeoutMs: UInt64,
        maxHeartbeatThrottleIntervalMs: UInt64,
        defaultHeartbeatThrottleIntervalMs: UInt64,
        maxActivitiesPerSecond: Double,
        maxTaskQueueActivitiesPerSecond: Double,
        gracefulShutdownMs: UInt64,
        workflowTaskPollerBehavior: TemporalWorker.Configuration.PollerBehavior,
        nonstickyToStickyRatio: Float,
        activityTaskPollerBehavior: TemporalWorker.Configuration.PollerBehavior,
        nexusTaskPollerBehavior: TemporalWorker.Configuration.PollerBehavior,
        nondeterminismAsWorkflowFail: Bool,
        nondeterminismTypes: [String],
        _ body: (UnsafePointer<TemporalCoreWorkerOptions>) throws -> T
    ) rethrows -> T {
        try namespace.withByteArrayRef { namespaceRef in
            try taskQueue.withByteArrayRef { taskQueueRef in
                try identity.withByteArrayRef { identityRef in
                    try nondeterminismTypes.withByteArrayRefArray { nondetArray in
                        try versioningStrategy.withVersioningStrategyOptions { versioningStrategyRef in
                            try workflowTaskPollerBehavior.withPollerBehaviorOptions { workflowTaskPollerBehaviorRef in
                                try activityTaskPollerBehavior.withPollerBehaviorOptions { activityTaskPollerBehaviorRef in
                                    try nexusTaskPollerBehavior.withPollerBehaviorOptions { nexusTaskPollerBehaviorRef in
                                        var opts = TemporalCoreWorkerOptions(
                                            namespace_: namespaceRef,
                                            task_queue: taskQueueRef,
                                            versioning_strategy: versioningStrategyRef,
                                            identity_override: identityRef,
                                            max_cached_workflows: maxCachedWorkflows,
                                            tuner: tuner,
                                            task_types: TemporalCoreWorkerTaskTypes(
                                                enable_workflows: hasWorkflows,
                                                enable_local_activities: hasWorkflows && hasActivities,
                                                enable_remote_activities: hasActivities,
                                                enable_nexus: false  // TODO: Support nexus
                                            ),
                                            sticky_queue_schedule_to_start_timeout_millis: stickyQueueTimeoutMs,
                                            max_heartbeat_throttle_interval_millis: maxHeartbeatThrottleIntervalMs,
                                            default_heartbeat_throttle_interval_millis: defaultHeartbeatThrottleIntervalMs,
                                            max_activities_per_second: maxActivitiesPerSecond,
                                            max_task_queue_activities_per_second: maxTaskQueueActivitiesPerSecond,
                                            graceful_shutdown_period_millis: gracefulShutdownMs,
                                            workflow_task_poller_behavior: workflowTaskPollerBehaviorRef,
                                            nonsticky_to_sticky_poll_ratio: nonstickyToStickyRatio,
                                            activity_task_poller_behavior: activityTaskPollerBehaviorRef,
                                            nexus_task_poller_behavior: nexusTaskPollerBehaviorRef,
                                            nondeterminism_as_workflow_fail: nondeterminismAsWorkflowFail,
                                            nondeterminism_as_workflow_fail_for_types: nondetArray,
                                            plugins: .init()
                                        )

                                        return try body(&opts)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension TemporalWorker.Configuration.VersioningStrategy {
    fileprivate func withVersioningStrategyOptions<T>(
        _ body: (TemporalCoreWorkerVersioningStrategy) throws -> T
    ) rethrows -> T {
        switch self.kind {
        case .none(let noneParameters):
            let buildId = noneParameters.buildId ?? ""

            return try buildId.withByteArrayRef { buildIdRef in
                var versioningStrategy = TemporalCoreWorkerVersioningStrategy()
                versioningStrategy.tag = None
                versioningStrategy.none = .init(build_id: buildIdRef)

                return try body(versioningStrategy)
            }
        case .deploymentBased(let deploymentBasedParameter):
            return try deploymentBasedParameter.deploymentVersion.buildId.withByteArrayRef { buildIdRef in
                try deploymentBasedParameter.deploymentVersion.deploymentName.withByteArrayRef { deploymentVersionRef in
                    var versioningStrategy = TemporalCoreWorkerVersioningStrategy()
                    versioningStrategy.tag = DeploymentBased
                    versioningStrategy.deployment_based = .init(
                        version: .init(deployment_name: deploymentVersionRef, build_id: buildIdRef),
                        use_worker_versioning: deploymentBasedParameter.useWorkerVersioning,
                        default_versioning_behavior: {
                            let behavior: Api.Enums.V1.VersioningBehavior =
                                switch deploymentBasedParameter.defaultVersioningBehavior.kind {
                                case .unspecified: .unspecified
                                case .pinned: .pinned
                                case .autoUpgrade: .autoUpgrade
                                }

                            return Int32(behavior.rawValue)
                        }()
                    )

                    return try body(versioningStrategy)
                }
            }
        case .legacyBuildIdBased(let legacyBuildIdBasedParameters):
            return try legacyBuildIdBasedParameters.buildId.withByteArrayRef { buildIdRef in
                var versioningStrategy = TemporalCoreWorkerVersioningStrategy()
                versioningStrategy.tag = LegacyBuildIdBased
                versioningStrategy.legacy_build_id_based = .init(build_id: buildIdRef)

                return try body(versioningStrategy)
            }
        }
    }
}

extension TemporalWorker.Configuration.PollerBehavior {
    fileprivate func withPollerBehaviorOptions<T>(
        _ body: (TemporalCorePollerBehavior) throws -> T
    ) rethrows -> T {
        switch self.kind {
        case .simpleMaximum(let maximum):
            let simpleMaximum = TemporalCorePollerBehaviorSimpleMaximum(simple_maximum: UInt(maximum))
            return try withUnsafePointer(to: simpleMaximum) { simpleMaximumRef in
                let behavior = TemporalCorePollerBehavior(
                    simple_maximum: simpleMaximumRef,
                    autoscaling: nil
                )

                return try body(behavior)
            }
        case .autoscaling(let minimum, let maximum, let initial):
            let autoscaling = TemporalCorePollerBehaviorAutoscaling(minimum: UInt(minimum), maximum: UInt(maximum), initial: UInt(initial))
            return try withUnsafePointer(to: autoscaling) { autoscalingRef in
                let behavior = TemporalCorePollerBehavior(
                    simple_maximum: nil,
                    autoscaling: autoscalingRef
                )

                return try body(behavior)
            }
        }
    }
}
