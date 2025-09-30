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

/// Factory protocol for creating interceptors that process workflows and activities within worker execution contexts.
public protocol WorkerInterceptor: Sendable {
    /// The type of workflow inbound interceptor this factory creates for processing incoming workflow requests.
    associatedtype WorkflowInboundInterceptorType: WorkflowInboundInterceptor = ForwardingWorkflowInboundInterceptor

    /// The type of workflow outbound interceptor this factory creates for processing outgoing workflow requests.
    associatedtype WorkflowOutboundInterceptorType: WorkflowOutboundInterceptor = ForwardingWorkflowOutboundInterceptor

    /// The type of activity inbound interceptor this factory creates for processing incoming activity requests.
    associatedtype ActivityInboundInterceptorType: ActivityInboundInterceptor = ForwardingActivityInboundInterceptor

    /// The type of activity outbound interceptor this factory creates for processing outgoing activity requests.
    associatedtype ActivityOutboundInterceptorType: ActivityOutboundInterceptor = ForwardingActivityOutboundInterceptor

    /// Creates a workflow inbound interceptor for processing incoming workflow requests.
    ///
    /// - Returns: A workflow inbound interceptor instance, or `nil` if no interception is needed.
    func makeWorkflowInboundInterceptor() -> WorkflowInboundInterceptorType?

    /// Creates a workflow outbound interceptor for processing outgoing workflow requests.
    ///
    /// - Returns: A workflow outbound interceptor instance, or `nil` if no interception is needed.
    func makeWorkflowOutboundInterceptor() -> WorkflowOutboundInterceptorType?

    /// Creates an activity inbound interceptor for processing incoming activity requests.
    ///
    /// - Returns: An activity inbound interceptor instance, or `nil` if no interception is needed.
    func makeActivityInboundInterceptor() -> ActivityInboundInterceptorType?

    /// Creates an activity outbound interceptor for processing outgoing activity requests.
    ///
    /// - Returns: An activity outbound interceptor instance, or `nil` if no interception is needed.
    func makeActivityOutboundInterceptor() -> ActivityOutboundInterceptorType?
}

extension WorkerInterceptor {
    /// Default implementation that returns no workflow inbound interceptor.
    ///
    /// - Returns: `nil` to indicate no interception is performed.
    public func makeWorkflowInboundInterceptor() -> WorkflowInboundInterceptorType? {
        return nil
    }

    /// Default implementation that returns no workflow outbound interceptor.
    ///
    /// - Returns: `nil` to indicate no interception is performed.
    public func makeWorkflowOutboundInterceptor() -> WorkflowOutboundInterceptorType? {
        return nil
    }

    /// Default implementation that returns no activity inbound interceptor.
    ///
    /// - Returns: `nil` to indicate no interception is performed.
    public func makeActivityInboundInterceptor() -> ActivityInboundInterceptorType? {
        return nil
    }

    /// Default implementation that returns no activity outbound interceptor.
    ///
    /// - Returns: `nil` to indicate no interception is performed.
    public func makeActivityOutboundInterceptor() -> ActivityOutboundInterceptorType? {
        return nil
    }
}

/// Default workflow inbound interceptor that forwards all requests without modification.
public struct ForwardingWorkflowInboundInterceptor: WorkflowInboundInterceptor {}

/// Default activity inbound interceptor that forwards all requests without modification.
public struct ForwardingActivityInboundInterceptor: ActivityInboundInterceptor {}

/// Default workflow outbound interceptor that forwards all requests without modification.
public struct ForwardingWorkflowOutboundInterceptor: WorkflowOutboundInterceptor {}

/// Default activity outbound interceptor that forwards all requests without modification.
public struct ForwardingActivityOutboundInterceptor: ActivityOutboundInterceptor {}
