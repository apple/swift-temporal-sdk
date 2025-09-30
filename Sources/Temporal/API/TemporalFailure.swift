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

/// A struct representing a temporal failure.
public struct TemporalFailure: Hashable, Sendable {
    private final class _Storage: @unchecked Sendable {
        var message: String
        var source: String
        var stackTrace: String
        var encodedAttributes: TemporalPayload?
        var cause: TemporalFailure?
        var failureInfo: FailureInfo?

        init(
            message: String,
            source: String,
            stackTrace: String,
            encodedAttributes: TemporalPayload? = nil,
            cause: TemporalFailure? = nil,
            failureInfo: FailureInfo? = nil
        ) {
            self.message = message
            self.source = source
            self.stackTrace = stackTrace
            self.encodedAttributes = encodedAttributes
            self.cause = cause
            self.failureInfo = failureInfo
        }

        func copy() -> Self {
            Self(
                message: self.message,
                source: self.source,
                stackTrace: self.stackTrace,
                encodedAttributes: self.encodedAttributes,
                cause: self.cause,
                failureInfo: self.failureInfo
            )
        }
    }
    public enum FailureInfo: Sendable, Hashable {
        public struct Application: Sendable, Hashable {
            /// The details of the error.
            public var details: [TemporalPayload]

            /// The string type of the error if any.
            public var type: String

            /// Boolean indicating wehter the error was set as non-retry.
            public var isNonRetryable: Bool

            /// Delay duration before the next retry attempt.
            public var nextRetryDelay: Duration?

            /// Initializes a new application error.
            ///
            /// - Parameters:
            ///   - details: The details of the error. Defaults to empty details.
            ///   - type: The string type of the error if any. Defaults to an empty String.
            ///   - isNonRetryable: Boolean indicating wehter the error was set as non-retry. Defaults to `false`.
            ///   - nextRetryDelay: Delay duration before the next retry attempt. Defaults to `nil`.
            public init(
                details: [TemporalPayload] = [],
                type: String = "",
                isNonRetryable: Bool = false,
                nextRetryDelay: Duration? = nil
            ) {
                self.details = details
                self.type = type
                self.isNonRetryable = isNonRetryable
                self.nextRetryDelay = nextRetryDelay
            }
        }

        public struct Cancelled: Sendable, Hashable {
            /// The details of the error.
            public var details: [TemporalPayload]

            /// Initializes a new cancelled error.
            ///
            /// - Parameters:
            ///   - details: The details of the error. Defaults to empty details.
            public init(
                details: [TemporalPayload] = []
            ) {
                self.details = details
            }
        }

        public struct Terminated: Sendable, Hashable {
            /// The details of the error.
            public var details: [TemporalPayload]

            /// Initializes a new terminated error.
            ///
            /// - Parameters:
            ///   - details: The details of the error. Defaults to empty details.
            public init(
                details: [TemporalPayload] = []
            ) {
                self.details = details
            }
        }

        public struct ChildWorkflowExecution: Sendable, Hashable {
            public var namespace: String

            public var workflowID: String

            public var runID: String

            public var workflowName: String

            public var retryState: RetryState

            public init(
                namespace: String,
                workflowID: String,
                runID: String,
                workflowName: String,
                retryState: RetryState
            ) {
                self.namespace = namespace
                self.workflowID = workflowID
                self.runID = runID
                self.workflowName = workflowName
                self.retryState = retryState
            }
        }

        public struct Activity: Sendable, Hashable {
            /// Scheduled event ID for this activity.
            public var scheduledEventID: Int

            /// Started event ID for this activity.
            public var startedEventID: Int

            /// Client/worker identity.
            public var identity: String

            /// Activity type name.
            public var activityType: String

            /// Activity ID.
            public var activityID: String

            /// Retry state.
            public var retryState: RetryState

            /// Initializes a new activity error.
            ///
            /// - Parameters:
            ///   - scheduledEventID: Scheduled event ID for this activity.
            ///   - startedEventID: Started event ID for this activity.
            ///   - identity: Client/worker identity.
            ///   - activityType: Activity type name
            ///   - activityID: Activity ID.
            ///   - retryState: Retry state.
            public init(
                scheduledEventID: Int,
                startedEventID: Int,
                identity: String,
                activityType: String,
                activityID: String,
                retryState: RetryState
            ) {
                self.scheduledEventID = scheduledEventID
                self.startedEventID = startedEventID
                self.identity = identity
                self.activityType = activityType
                self.activityID = activityID
                self.retryState = retryState
            }
        }

        public struct Timeout: Sendable, Hashable {
            /// The type of timeout.
            public var type: TimeoutType
            /// The details of the last heartbeat.
            public var lastHeartbeatDetails: [TemporalPayload]

            /// Initializes a new terminated error.
            ///
            /// - Parameters:
            ///   - type: The type of timeout.
            ///   - lastHeartbeatDetails: The details of the last heartbeat. Defaults to empty details.
            public init(
                type: TimeoutType,
                lastHeartbeatDetails: [TemporalPayload] = []
            ) {
                self.type = type
                self.lastHeartbeatDetails = lastHeartbeatDetails
            }
        }
        /// Indicates application failure.
        case application(Application)
        /// Indicates cancelled failure.
        case cancelled(Cancelled)
        /// Indicates terminated failure.
        case terminated(Terminated)
        /// Indicates a child workflow execution failure.
        case childWorkflowExecution(ChildWorkflowExecution)
        /// Indicates an activity failure.
        case activity(Activity)
        /// Indicates a timeout failure.
        case timeout(Timeout)

        /// This is an extensible enum. Matching exhaustively over this is not supported.
        case DO_NOT_EXHAUSTIVELY_MATCH_OVER_THIS_ENUM
    }

    /// The failure's message.
    public var message: String {
        get { self._storage.message }
        set { self._uniqueStorage().message = newValue }
    }

    /// The source this failure originated.
    public var source: String {
        get { self._storage.source }
        set { self._uniqueStorage().source = newValue }
    }

    /// The failure's stack trace.
    public var stackTrace: String {
        get { self._storage.stackTrace }
        set { self._uniqueStorage().stackTrace = newValue }
    }

    /// Alternative way to supply `message` and `stack_trace` and possibly other attributes, used for encryption of
    /// errors originating in user code which might contain sensitive information.
    ///
    /// The `encoded_attributes` Payload could represent any serializable object, e.g. JSON object or a `Failure` proto
    /// message.
    ///
    /// SDK authors:
    /// - The SDK should provide a default `encodeFailureAttributes` and `decodeFailureAttributes` implementation that:
    ///   - Uses a JSON object to represent `{ message, stack_trace }`.
    ///   - Overwrites the original message with "Encoded failure" to indicate that more information could be extracted.
    ///   - Overwrites the original stack_trace with an empty string.
    ///   - The resulting JSON object is converted to Payload using the default PayloadConverter and should be processed
    ///     by the user-provided PayloadCodec
    public var encodedAttributes: TemporalPayload? {
        get { self._storage.encodedAttributes }
        set { self._uniqueStorage().encodedAttributes = newValue }
    }

    /// The failure's cause.
    public var cause: TemporalFailure? {
        get { self._storage.cause }
        set { self._uniqueStorage().cause = newValue }
    }

    /// The failure's info.
    public var failureInfo: FailureInfo? {
        get { self._storage.failureInfo }
        set { self._uniqueStorage().failureInfo = newValue }
    }

    private var _storage: _Storage

    /// Initializes a new temporal failure.
    ///
    /// - Parameters:
    ///   - message: The failure's message.
    ///   - source: The source this failure originated in.
    ///   - stackTrace: The failure's stack trace.
    ///   - encodedAttributes: Alternative way to supply `message` and `stack_trace` and possibly other attributes,
    ///   used for encryption of errors originating in user code which might contain sensitive information.
    ///   - cause: The failure's cause.
    ///   - failureInfo: The failure's info.
    public init(
        message: String,
        source: String,
        stackTrace: String,
        encodedAttributes: TemporalPayload? = nil,
        cause: TemporalFailure? = nil,
        failureInfo: FailureInfo? = nil
    ) {
        self._storage = .init(
            message: message,
            source: source,
            stackTrace: stackTrace,
            encodedAttributes: encodedAttributes,
            cause: cause,
            failureInfo: failureInfo
        )
    }

    // This is the magic bit
    private mutating func _uniqueStorage() -> _Storage {
        if !isKnownUniquelyReferenced(&_storage) {
            _storage = _storage.copy()
        }
        return _storage
    }
}

extension TemporalFailure {
    public static func == (lhs: TemporalFailure, rhs: TemporalFailure) -> Bool {
        lhs.message == rhs.message
            && lhs.source == rhs.source
            && lhs.stackTrace == rhs.stackTrace
            && lhs.encodedAttributes == rhs.encodedAttributes
            && lhs.cause == rhs.cause
            && lhs.failureInfo == rhs.failureInfo
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.message)
        hasher.combine(self.source)
        hasher.combine(self.stackTrace)
        hasher.combine(self.encodedAttributes)
        hasher.combine(self.cause)
        hasher.combine(self.failureInfo)
    }
}
