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

import Logging
import Synchronization

extension ActivityWorker {
    /// State management and lifecycle coordination for individual activity executions.
    ///
    /// `RunningActivity` provides coordination between activity execution and external cancellation
    /// requests. It manages the transition between different execution states and ensures proper cleanup
    /// when activities are cancelled or complete.
    ///
    /// ## State Lifecycle
    ///
    /// The activity progresses through these states:
    /// 1. `initial` - Created but not yet executing
    /// 2. `running` - Active execution with cancellation monitoring
    /// 3. `cancelled` - Stopped due to cancellation with recorded reason
    /// 4. `finished` - Completed execution (normal or error)
    final class RunningActivity: Sendable {
        /// Represents the possible execution states of a running activity.
        enum State: Sendable {
            /// The activity has been created but execution has not yet begun.
            case initial
            /// The activity is actively executing with a continuation waiting for potential cancellation
            /// signals.
            case running(CheckedContinuation<Void, Never>)
            /// The activity has been cancelled and is no longer executing, with the cancellation reason
            /// preserved.
            case cancelled(ActivityCancellationReason)
            /// The activity execution has completed successfully or with an error.
            case finished
        }

        /// Thread-safe container protecting the activity's current execution state.
        let state: Mutex<State> = .init(.initial)

        /// The reason for activity cancellation if the activity has been cancelled.
        ///
        /// This property returns the specific cancellation reason when the activity state is `cancelled`,
        /// or `nil` if the activity is still running or has completed normally.
        var cancellationReason: ActivityCancellationReason? {
            state.withLock {
                switch $0 {
                case .cancelled(let reason):
                    reason
                default:
                    nil
                }
            }
        }

        /// Suspends the current task until the activity receives a cancellation signal.
        ///
        /// This method provides the coordination mechanism between the activity execution task and
        /// external cancellation requests. It transitions the activity to the running state and waits for either
        /// explicit cancellation or task cancellation cleanup.
        ///
        /// - Parameter logger: The logger instance for diagnostic and debugging output.
        /// - Important: This method should only be called once per activity instance.
        func waitForCancellation(logger: Logger) async {
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    let maybeContinuation: CheckedContinuation<Void, Never>? = state.withLock {
                        switch $0 {
                        case .initial:
                            $0 = .running(continuation)
                            return nil
                        case .running, .finished:
                            fatalError("Activity cancellation observation should only be used once")
                        case .cancelled:
                            return continuation
                        }
                    }

                    maybeContinuation?.resume()
                }
            } onCancel: {
                // This is only happening if activity finished and we are cleaning up this cancellation handler.
                let maybeContinuation: CheckedContinuation<Void, Never>? = state.withLock {
                    switch $0 {
                    case .initial, .cancelled, .finished:
                        fatalError("Activity cancellation happened at unexpected time")
                    case .running(let continuation):
                        return continuation
                    }
                }

                maybeContinuation?.resume()
            }
        }

        /// Transitions the activity to the cancelled state with the specified reason.
        ///
        /// This method safely transitions the activity from its current state to cancelled, recording the
        /// cancellation reason and resuming any waiting cancellation observers.
        ///
        /// - Parameter reason: The specific reason why the activity is being cancelled.
        /// - Important: This method should only be called once per activity instance.
        func cancel(reason: ActivityCancellationReason) {
            let maybeContinuation: CheckedContinuation<Void, Never>? = state.withLock {
                switch $0 {
                case .initial:
                    $0 = .cancelled(reason)
                    return nil
                case .running(let continuation):
                    $0 = .cancelled(reason)
                    return continuation
                case .cancelled, .finished:
                    fatalError("Activity should only be cancelled once.")
                }
            }

            maybeContinuation?.resume()
        }
    }
}
