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

import DequeModule
import Synchronization

/// An executor used for workflows.
///
/// This executor buffers all enqueued jobs and exposes a run method to run them inline.
package final class WorkflowTaskExecutor: TaskExecutor, SerialExecutor, Sendable {
    private let jobs: Mutex<Deque<(UInt64, UnownedJob)>>

    package init() {
        var jobs = Deque<(UInt64, UnownedJob)>()
        // We are presizing this so that we avoid unnecesary allocations.
        // 64 should be more than enough for the average workflow
        jobs.reserveCapacity(64)
        self.jobs = .init(jobs)
    }

    package func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        let taskID = _getJobTaskId(unownedJob)
        self.jobs.withLock { $0.append((taskID, unownedJob)) }
    }

    /// Runs all the jobs inline until there are no more jobs.
    package func run() {
        // The goal is to ensure complete determinstic ordering.
        // Initially we just ran the enqueued jobs in the order we buffered them
        // but the Swift runtime commonly enqueues multiple jobs for a single task
        // without the task actually suspending. This is something that we cannot
        // rely on to stay this way so we must enforce a different mechanism to ensure
        // deterministic ordering. The below algorithm picks the first buffered job
        // and then continues to run jobs from the same task until there are no more.
        // It then picks the next job and does the same.
        var currentJobID: UInt64?
        while true {
            let (next): (UInt64, UnownedJob)?

            if let previousJobID = currentJobID {
                next = self.jobs.withLock {
                    // The linear lookup is most likely fine since that's often
                    // faster than hasing for a small number of elements. However,
                    // the removal afterwards will force a reallocation to compact the
                    // dequeue. That's okay for now but we might want to revisit
                    // this later.
                    // TODO: Investigate a different data structure.
                    guard let index = $0.firstIndex(where: { $0.0 == previousJobID }) else {
                        return $0.popFirst()
                    }
                    return $0.remove(at: index)
                }
            } else {
                next = self.jobs.withLock({ $0.popFirst() })
            }

            guard let (jobID, nextJob) = next else {
                // No job so we can exit
                return
            }
            currentJobID = jobID
            nextJob.runSynchronously(
                isolatedTo: self.asUnownedSerialExecutor(),
                taskExecutor: self.asUnownedTaskExecutor()
            )
        }
    }
}

/// Primarily a debug utility.
///
/// If the passed in ExecutorJob is a Task, returns the complete 64bit TaskId,
/// otherwise returns only the job's 32bit Id.
///
/// - Returns: the Id stored in this ExecutorJob or Task, for purposes of debug printing
// This is dangerous but currently the only acceptable way to get a stable identifier
// for a given task.
@_silgen_name("swift_task_getJobTaskId")
internal func _getJobTaskId(_ job: UnownedJob) -> UInt64
