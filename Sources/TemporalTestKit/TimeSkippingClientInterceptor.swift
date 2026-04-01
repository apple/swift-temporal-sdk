//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Temporal SDK open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Temporal SDK project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Temporal SDK project authors
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

#if canImport(Testing)
import Temporal

/// A client interceptor that automatically unlocks time skipping on the
/// Temporal time-skipping test server when waiting for workflow results.
///
/// When the time-skipping test server is active, timers in workflows only advance
/// when time skipping is unlocked. This interceptor unlocks time skipping around
/// ``fetchWorkflowHistoryEvents`` calls that are waiting for a workflow close event
/// (which is the pattern used by ``UntypedWorkflowHandle/result(followRuns:resultTypes:callOptions:)``).
///
/// This interceptor is auto-injected by ``TemporalTestServer`` when connecting to
/// a time-skipping test server. You do not need to add it manually.
struct TimeSkippingClientInterceptor: Temporal.ClientInterceptor, Sendable {
    private let testServer: TemporalTestServer

    package init(testServer: TemporalTestServer) {
        self.testServer = testServer
    }

    var clientOutboundInterceptor: Outbound? {
        Outbound(testServer: self.testServer)
    }

    struct Outbound: Temporal.ClientOutboundInterceptor {
        private let testServer: TemporalTestServer

        init(testServer: TemporalTestServer) {
            self.testServer = testServer
        }

        func fetchWorkflowHistoryEvents(
            input: FetchWorkflowHistoryEventsInput,
            next: (FetchWorkflowHistoryEventsInput) async throws -> [Api.History.V1.HistoryEvent]
        ) async throws -> [Api.History.V1.HistoryEvent] {
            // Only unlock time skipping when waiting for a close event, which
            // is the pattern used by result() to poll for workflow completion.
            guard input.waitNewEvent && input.eventFilterType == .closeEvent else {
                return try await next(input)
            }

            guard testServer.isAutoTimeSkippingEnabled else {
                return try await next(input)
            }

            return try await testServer.withTimeSkippingUnlocked {
                try await next(input)
            }
        }
    }
}
#endif
