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

/// Protocol for a worker interceptor that processes workflows and activities within worker execution contexts.
public protocol WorkerInterceptor: Sendable {
    /// The type of workflow inbound interceptor for processing incoming workflow requests.
    associatedtype WorkflowInboundInterceptorType: WorkflowInboundInterceptor = ForwardingWorkflowInboundInterceptor

    /// The type of workflow outbound interceptor for processing outgoing workflow requests.
    associatedtype WorkflowOutboundInterceptorType: WorkflowOutboundInterceptor = ForwardingWorkflowOutboundInterceptor

    /// The type of activity inbound interceptor for processing incoming activity requests.
    associatedtype ActivityInboundInterceptorType: ActivityInboundInterceptor = ForwardingActivityInboundInterceptor

    /// The type of activity outbound interceptor for processing outgoing activity requests.
    associatedtype ActivityOutboundInterceptorType: ActivityOutboundInterceptor = ForwardingActivityOutboundInterceptor

    /// The workflow inbound interceptor for processing incoming workflow requests, or `nil` if no interception is needed.
    var workflowInboundInterceptor: WorkflowInboundInterceptorType? { get }

    /// The workflow outbound interceptor for processing outgoing workflow requests, or `nil` if no interception is needed.
    var workflowOutboundInterceptor: WorkflowOutboundInterceptorType? { get }

    /// The activity inbound interceptor for processing incoming activity requests, or `nil` if no interception is needed.
    var activityInboundInterceptor: ActivityInboundInterceptorType? { get }

    /// The activity outbound interceptor for processing outgoing activity requests, or `nil` if no interception is needed.
    var activityOutboundInterceptor: ActivityOutboundInterceptorType? { get }
}

extension WorkerInterceptor {
    /// Default implementation that returns no workflow inbound interceptor.
    public var workflowInboundInterceptor: WorkflowInboundInterceptorType? { nil }

    /// Default implementation that returns no workflow outbound interceptor.
    public var workflowOutboundInterceptor: WorkflowOutboundInterceptorType? { nil }

    /// Default implementation that returns no activity inbound interceptor.
    public var activityInboundInterceptor: ActivityInboundInterceptorType? { nil }

    /// Default implementation that returns no activity outbound interceptor.
    public var activityOutboundInterceptor: ActivityOutboundInterceptorType? { nil }
}

/// Default workflow inbound interceptor that forwards all requests without modification.
public struct ForwardingWorkflowInboundInterceptor: WorkflowInboundInterceptor {}

/// Default activity inbound interceptor that forwards all requests without modification.
public struct ForwardingActivityInboundInterceptor: ActivityInboundInterceptor {}

/// Default workflow outbound interceptor that forwards all requests without modification.
public struct ForwardingWorkflowOutboundInterceptor: WorkflowOutboundInterceptor {}

/// Default activity outbound interceptor that forwards all requests without modification.
public struct ForwardingActivityOutboundInterceptor: ActivityOutboundInterceptor {}
