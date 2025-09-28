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

import Configuration

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension TemporalWorker {
    /// Configuration settings for the Temporal worker controlling operational behavior and connection
    /// parameters.
    ///
    /// The configuration defines how the worker connects to the Temporal server, manages task execution,
    /// and handles various operational aspects like concurrency limits, timeouts, and versioning.
    ///
    /// ## Creating a Configuration
    ///
    /// Initialize with required parameters:
    ///
    /// ```swift
    /// let config = TemporalWorker.Configuration(
    ///     namespace: "production",
    ///     taskQueue: "order-processing",
    ///     instrumentation: .init(serverHostname: "temporal.example.com")
    /// )
    /// ```
    ///
    /// Or from a configuration using `ConfigReader`:
    ///
    /// ```swift
    /// let config = try TemporalWorker.Configuration(
    ///     container: configReader
    /// )
    /// ```
    ///
    /// ## Customizing Behavior
    ///
    /// Adjust operational settings after initialization:
    ///
    /// ```swift
    /// config.maxConcurrentWorkflowTasks = 50
    /// config.maxConcurrentActivities = 200
    /// config.gracefulShutdownPeriod = .seconds(30)
    /// ```
    public struct Configuration: Sendable {
        /// Versioning strategy of the ``TemporalWorker``.
        public struct VersioningStrategy: Hashable, Sendable {
            /// Represents a version of a ``TemporalWorker`` within a Worker Deployment.
            public struct DeploymentVersion: Hashable, Sendable {
                /// Identifies the Worker Deployment this Version is part of.
                public var deploymentName: String
                /// A unique identifier for this Version within the Deployment it is a part of.
                ///
                /// Not necessarily unique within the namespace.
                /// The combination of `deployment_name` and `build_id` uniquely identifies this
                /// Version within the namespace, because Deployment names are unique within a namespace.
                public var buildId: String

                /// Creates a deployment version of a ``TemporalWorker``.
                ///
                /// - Parameters:
                ///   - deploymentName: Identifies the Worker Deployment this Version is part of.
                ///   - buildId: A unique identifier for this Version within the Deployment it is a part of.
                public init(deploymentName: String, buildId: String) {
                    self.deploymentName = deploymentName
                    self.buildId = buildId
                }
            }

            /// Versioning Behavior specifies if and how a workflow execution moves between Worker Deployment Versions.
            public struct DefaultVersioningBehavior: Hashable, Sendable {
                package enum Kind: Hashable, Sendable {
                    case unspecified
                    case pinned
                    case autoUpgrade
                }

                package let kind: Kind

                private init(_ kind: Kind) { self.kind = kind }

                /// Workflow execution does not have a Versioning Behavior and is called Unversioned.
                ///
                /// This is the legacy behavior. An Unversioned workflow's task can go to any Unversioned worker (see `WorkerVersioningMode`.)
                public static let unspecified = Self(.unspecified)

                /// Workflow will start on the Current Deployment Version of its Task Queue, and then will be pinned to that same Deployment Version until completion.
                ///
                /// The Version that this Workflow is pinned to is specified in `versioning_info.version`.
                public static let pinned = Self(.pinned)

                /// Workflow will automatically move to the Current Deployment Version of its Task Queue when the next workflow task is dispatched.
                public static let autoUpgrade = Self(.autoUpgrade)
            }

            /// Parameters for `.none` versioning.
            public struct NoneParameters: Hashable, Sendable {
                /// Build ID may still be passed as a way to identify the worker, or may be left empty.
                public var buildId: String?

                /// Don't enable any versioning.
                ///
                /// - Parameter buildId: Build ID may still be passed as a way to identify the worker, or may be left empty.
                public init(buildId: String? = nil) {
                    self.buildId = buildId
                }
            }

            /// Parameters for `.deploymentBased` versioning.
            public struct DeploymentBasedParameters: Hashable, Sendable {
                /// The deployment version of this worker.
                public var deploymentVersion: DeploymentVersion
                /// If set, opts in to the Worker Deployment Versioning feature, meaning this worker will only receive tasks for workflows it claims to be compatible with.
                public var useWorkerVersioning: Bool
                /// The default versioning behavior to use for workflows that do not pass one to Core.
                ///
                /// It is a startup-time error to specify ``DefaultVersioningBehavior/unspecified`` here.
                public var defaultVersioningBehavior: DefaultVersioningBehavior

                /// Use the modern deployment-based versioning, or just pass a deployment version.
                ///
                /// - Parameters:
                ///   - deploymentVersion: The deployment version of this worker.
                ///   - useWorkerVersioning: If set, opts in to the Worker Deployment Versioning feature, meaning this worker will only
                ///                          receive tasks for workflows it claims to be compatible with.
                ///   - defaultVersioningBehavior: The default versioning behavior to use for workflows that do not pass one to Core.
                public init(
                    deploymentVersion: DeploymentVersion,
                    useWorkerVersioning: Bool,
                    defaultVersioningBehavior: DefaultVersioningBehavior
                ) {
                    self.deploymentVersion = deploymentVersion
                    self.useWorkerVersioning = useWorkerVersioning
                    self.defaultVersioningBehavior = defaultVersioningBehavior
                }
            }

            /// Parameters for `.legacyBuildIdBased` versioning.
            public struct LegacyBuildIdBasedParameters: Hashable, Sendable {
                /// A Build ID to use, must be non-empty.
                public var buildId: String

                /// Use the legacy build-id-based whole worker versioning.
                ///
                /// - Parameter buildId: The Build ID to use, must be non-empty.
                public init(buildId: String) {
                    self.buildId = buildId
                }
            }

            package enum Kind: Hashable, Sendable {
                case none(NoneParameters)
                case deploymentBased(DeploymentBasedParameters)
                case legacyBuildIdBased(LegacyBuildIdBasedParameters)
            }

            package let kind: Kind

            private init(_ kind: Kind) { self.kind = kind }

            /// Don't enable any versioning.
            ///
            /// - Parameter noneParameters: Parameters for no versioning.
            public static func none(_ noneParameters: NoneParameters) -> Self {
                .init(.none(noneParameters))
            }

            /// Use the modern deployment-based versioning, or just pass a deployment version.
            ///
            /// - Parameters:
            ///   - deploymentBasedParameters: Parameters for deployment-based versioning.
            public static func deploymentBased(_ deploymentBasedParameters: DeploymentBasedParameters) -> Self {
                .init(.deploymentBased(deploymentBasedParameters))
            }

            /// Use the legacy build-id-based whole worker versioning.
            ///
            /// - Parameter legacyBuiltIdBasedParameters: Parameters for legacy buildId-based versioning.
            public static func legacyBuildIdBased(_ legacyBuiltIdBasedParameters: LegacyBuildIdBasedParameters) -> Self {
                .init(.legacyBuildIdBased(legacyBuiltIdBasedParameters))
            }
        }

        /// Different strategies for task polling.
        public struct PollerBehavior: Hashable, Sendable {
            package enum Kind: Hashable, Sendable {
                /// Will attempt to poll as long as a slot is available, up to the provided maximum. Cannot
                /// be less than two for workflow tasks, or one for other tasks.
                case simpleMaximum(maximum: Int)

                /// Will automatically scale the number of pollers based on feedback from the server. Still
                /// requires a slot to be available before beginning polling.
                case autoscaling(
                    /// At least this many poll calls will always be attempted (assuming slots are available).
                    /// Cannot be zero.
                    minimum: Int,
                    /// At most this many poll calls will ever be open at once. Must be >= `minimum`.
                    maximum: Int,
                    /// This many polls will be attempted initially before scaling kicks in. Must be between
                    /// `minimum` and `maximum`.
                    initial: Int
                )
            }

            package let kind: Kind

            private init(_ kind: Kind) {
                self.kind = kind
            }

            /// Will attempt to poll as long as a slot is available, up to the provided maximum.
            ///
            /// Cannot be less than two for workflow tasks, or one for other tasks.
            ///
            /// - Parameter maximum: Will attempt to poll as long as a slot is available, up to the provided maximum. Cannot be less than two for workflow tasks, or one for other tasks.
            public static func simpleMaximum(maximum: Int) -> Self {
                .init(.simpleMaximum(maximum: maximum))
            }

            /// Will automatically scale the number of pollers based on feedback from the server.
            ///
            /// Still requires a slot to be available before beginning polling.
            ///
            /// - Parameters:
            ///   - minimum: At least this many poll calls will always be attempted (assuming slots are available). Cannot be zero.
            ///   - maximum: At most this many poll calls will ever be open at once. Must be >= `minimum`.
            ///   - initial: This many polls will be attempted initially before scaling kicks in. Must be between `minimum` and `maximum`.
            public static func autoscaling(
                minimum: Int,
                maximum: Int,
                initial: Int
            ) -> Self {
                .init(.autoscaling(minimum: minimum, maximum: maximum, initial: initial))
            }
        }

        /// The name of the SDK being implemented on top of the Core SDK.
        ///
        /// Is set as `client-name` header in all RPC calls.
        static let workerClientName: String = "swift-temporal"

        /// The version of the SDK being implemented on top of the Core SDK.
        ///
        /// Is set as `client-version` header in all RPC calls. The server decides if the client is supported based on this.
        static let workerClientVersion: String = Constants.sdkVersion  // derived from current git tag / commit

        /// The namespace where this worker polls for tasks.
        ///
        /// Namespaces provide isolation between different environments or tenants within a
        /// Temporal server cluster.
        public var namespace: String

        /// The name of the task queue this worker monitors for available tasks.
        ///
        /// Task queues route workflow and activity tasks to appropriate workers.
        /// Multiple workers can poll the same task queue for load balancing.
        public var taskQueue: String
        /// Configuration settings for instrumentation including tracing, metrics, and logging.
        public var instrumentation: Instrumentation
        /// A human-readable identifier for this worker client instance.
        ///
        /// This identifier appears in server logs and monitoring tools to help distinguish between
        /// different worker instances.
        /// Versioning strategy of the worker.
        public var versioningStrategy: VersioningStrategy
        /// A human-readable string that identifies the worker client.
        public var clientIdentity: String

        /// An optional override for the default worker identity string.
        ///
        /// When provided, this value replaces the automatically generated client identity.
        public var identityOverride: String?

        /// The data converter used for serializing and deserializing payloads.
        ///
        /// The data converter handles encoding workflow inputs, outputs, and activity data for
        /// transmission between the worker and server.
        public var dataConverter: DataConverter

        /// A collection of interceptors that modify worker behavior in a chain-of-responsibility pattern.
        ///
        /// Earlier interceptors in the array wrap later ones. By default, includes
        /// ``TemporalWorkerTracingInterceptor`` for distributed tracing.
        public var interceptors: [any WorkerInterceptor]

        // –– Workflows ––
        /// Polling behavior for workflows (default max `5`).
        public var workflowTaskPollerBehavior: PollerBehavior = .simpleMaximum(maximum: 5)
        /// Maximum number of workflow instances to cache in memory (default `1000`).
        public var maxCachedWorkflows: Int = 1_000
        /// Maximum concurrent workflow tasks the worker will execute (default `100`).
        public var maxConcurrentWorkflowTasks: Int = 100
        /// Ratio of non-sticky to sticky workflow task polls (0.0–1.0, default `0.2`).
        public var nonstickyToStickyPollRatio: Double = 0.2
        /// Timeout for a sticky workflow task from schedule to start before falling back (default `10 sec`).
        public var stickyQueueScheduleToStartTimeout: Duration = .seconds(10)

        // –– Activities ––
        /// Polling behavior for activities (default max `5`).
        public var activityTaskPollerBehavior: PollerBehavior = .simpleMaximum(maximum: 5)
        /// Maximum concurrent remote activities (default `100`).
        public var maxConcurrentActivities: Int = 100
        /// Maximum concurrent local activities (default `100`).
        public var maxConcurrentLocalActivities: Int = 100
        /// If true, disables polling and execution of remote activities (default `false`).
        public var noRemoteActivities: Bool = false
        /// Global throttle for activity start rate (units/sec, default `100_000`).
        public var maxActivitiesPerSecond: Double = 100_000

        /// The throttle for activity start rate per task queue in activities per second.
        ///
        /// This limit applies individually to each task queue, allowing fine-grained control over activity execution rates.
        public var maxTaskQueueActivitiesPerSecond: Double = 100_000

        /// The maximum number of simultaneous polls for activity tasks from the server.
        ///
        /// More polls reduce task pickup latency but increase server load and network usage.
        public var maxConcurrentActivityTaskPolls: Int = 5

        // –– Heartbeat throttling ––

        /// The default interval between activity heartbeat signals sent to the server.
        ///
        /// Heartbeats indicate that long-running activities are still alive and making progress.
        /// Shorter intervals provide faster failure detection.
        public var defaultHeartbeatThrottleInterval: Duration = .seconds(30)

        /// The maximum allowed interval between activity heartbeat signals.
        ///
        /// Activities cannot extend their heartbeat interval beyond this limit, ensuring timely failure
        /// detection for unresponsive activities.
        public var maxHeartbeatThrottleInterval: Duration = .seconds(60)

        // –– Misc ––
        /// Milliseconds to wait for in-flight tasks on shutdown before force exit (default `0 sec`).
        public var gracefulShutdownPeriod: Duration = .seconds(0)
        /// Polling behavior for nexus tasks (default max `5`).
        public var nexusTaskPollerBehavior: PollerBehavior = .simpleMaximum(maximum: 5)
        /// Skip fetching server system info on startup (default `false`).
        public var skipGetSystemInfo: Bool = false

        /// Creates a Temporal worker configuration with the specified parameters.
        ///
        /// The configuration includes a tracing interceptor by default. Override the `interceptors`
        /// parameter to customize or disable tracing behavior.
        ///
        /// - Parameters:
        ///   - namespace: Temporal namespace where this worker will poll tasks.
        ///   - taskQueue: Name of the task queue to poll.
        ///   - instrumentation: The worker client's instrumentation configuration.
        ///   - versioningStrategy: Versioning strategy of the worker, defaults to none.
        ///   - clientIdentity: A human-readable string that identifies the worker client. By default, it is set to the SDK name and version followed by a randomly generated ID.
        ///   - dataConverter: Converts to encode and decode ``TemporalPayload``s before sending it.
        ///   - interceptors: Interceptors of the worker, earlier ones wrap later ones. Defaults to a tracing interceptor.
        public init(
            namespace: String,
            taskQueue: String,
            instrumentation: Instrumentation,
            versioningStrategy: VersioningStrategy = .none(.init()),
            clientIdentity: String? = nil,
            dataConverter: DataConverter = DataConverter.default,
            interceptors: [any WorkerInterceptor] = [TemporalWorkerTracingInterceptor()]
        ) {
            self.namespace = namespace
            self.taskQueue = taskQueue
            self.instrumentation = instrumentation
            self.versioningStrategy = versioningStrategy
            self.clientIdentity =
                clientIdentity
                ?? "\(Self.workerClientName)-\(Self.workerClientVersion)-\(UUID().uuidString.replacingOccurrences(of: "-", with: "").suffix(5))"
            self.dataConverter = dataConverter
            self.interceptors = interceptors
        }

        /// Creates a Temporal worker configuration from external configuration data.
        ///
        /// This initializer reads configuration values from a `ConfigReader`, typically loaded from
        /// environment variables or configuration files. The tracing interceptor is enabled by default -
        /// override the `interceptors` parameter to customize this behavior.
        ///
        /// ## Required configuration keys
        ///
        /// The following keys must be present in the configuration:
        /// - `worker.namespace`: The Temporal namespace where this worker polls for tasks
        /// - `worker.taskqueue`: The name of the task queue to monitor
        /// - `worker.buildid`: A unique identifier for this worker build
        /// - `worker.client.instrumentation.serverhostname`: The Temporal server
        /// hostname for instrumentation
        ///
        /// ## Optional configuration keys
        ///
        /// - `worker.client.identity`: A human-readable worker client identifier (defaults to
        /// SDK name and version)
        ///
        /// - Parameters:
        ///   - configReader: The configuration reader containing the required configuration values.
        ///   - dataConverter: The converter for encoding and decoding payloads. Defaults to the
        ///   standard converter.
        ///   - interceptors: A collection of worker interceptors. Defaults to tracing interceptor only.
        /// - Throws: Configuration errors if required keys are missing or invalid.
        public init(
            configReader: ConfigReader,
            dataConverter: DataConverter = DataConverter.default,
            interceptors: [any WorkerInterceptor] = [TemporalWorkerTracingInterceptor()]
        ) throws {
            let (namespace, taskQueue, workerBuildID, clientIdentity) = try configReader.withSnapshot { snapshotContainer in
                try (
                    snapshotContainer.requiredString(forKey: .workerNamespace),
                    snapshotContainer.requiredString(forKey: .workerTaskQueue),
                    snapshotContainer.requiredString(forKey: .workerBuildId),
                    snapshotContainer.string(forKey: .workerClientIdentity)  // defaults to `nil`
                )
            }

            try self.init(
                namespace: namespace,
                taskQueue: taskQueue,
                instrumentation: .init(configReader: configReader),
                versioningStrategy: .none(.init(buildId: workerBuildID)),
                clientIdentity: clientIdentity,
                dataConverter: dataConverter,
                interceptors: interceptors
            )
        }
    }
}
