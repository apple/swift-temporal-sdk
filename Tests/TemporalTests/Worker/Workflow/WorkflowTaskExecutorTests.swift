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

import Synchronization
import Temporal
import TemporalTestKit
import Testing

// Due to a compiler bug we need to wrap mutex into a box otherwise we get Sendable errors
private final class Box<Value: ~Copyable & Sendable>: Sendable {
    let value: Value

    init(value: consuming Value) {
        self.value = value
    }
}

extension TestServerDependentTests {
    @Suite(.tags(.workflowTests))
    struct WorkflowTaskExecutorTests {
        @Test
        func unstructuredTask() async throws {
            let executor = WorkflowTaskExecutor()
            let task = Task(executorPreference: executor) {}
            executor.run()
            await task.value
        }

        @Test
        func childTask() async throws {
            let executor = WorkflowTaskExecutor()
            await withTaskGroup(of: Void.self) { group in
                group.addTask(executorPreference: executor) {}
                executor.run()
            }
        }

        @Test
        func multipleChildTasks() async throws {
            for _ in 0...100 {
                let executor = WorkflowTaskExecutor()
                let results = Box(value: Mutex([Int]()))
                await withTaskGroup(of: Void.self) { group in
                    group.addTask(executorPreference: executor) {
                        results.value.withLock { $0.append(1) }
                    }
                    group.addTask(executorPreference: executor) {
                        results.value.withLock { $0.append(2) }
                    }
                    group.addTask(executorPreference: executor) {
                        results.value.withLock { $0.append(3) }
                    }
                    executor.run()
                    await group.waitForAll()
                    #expect(results.value.withLock { $0 } == [1, 2, 3])
                }
            }
        }

        @Test
        func taskGroupWaitForAll() async throws {
            for _ in 0...100 {
                let executor = WorkflowTaskExecutor()
                let results = Box(value: Mutex([Int]()))
                await withTaskGroup(of: Void.self) { group in
                    group.addTask(executorPreference: executor) {
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask(executorPreference: executor) {
                                results.value.withLock { $0.append(1) }
                            }
                            group.addTask(executorPreference: executor) {
                                results.value.withLock { $0.append(2) }
                            }
                            group.addTask(executorPreference: executor) {
                                results.value.withLock { $0.append(3) }
                            }
                            await group.waitForAll()
                        }
                    }

                    executor.run()
                    await group.waitForAll()
                    #expect(results.value.withLock { $0 } == [1, 2, 3])
                }
            }
        }

        @Test
        func taskGroupNext() async throws {
            for _ in 0...100 {
                let executor = WorkflowTaskExecutor()
                let results = Box(value: Mutex([Int]()))
                await withTaskGroup(of: Void.self) { group in
                    group.addTask(executorPreference: executor) {
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask(executorPreference: executor) {
                                results.value.withLock { $0.append(1) }
                            }
                            group.addTask(executorPreference: executor) {
                                results.value.withLock { $0.append(2) }
                            }
                            group.addTask(executorPreference: executor) {
                                results.value.withLock { $0.append(3) }
                            }
                            await group.next()
                            await group.next()
                            await group.next()
                        }
                    }

                    executor.run()
                    await group.waitForAll()
                    #expect(results.value.withLock { $0 } == [1, 2, 3])
                }
            }
        }

        @Test
        func multipleChildTasksWithAwaitOutcall() async throws {
            for _ in 0...100 {
                let executor = WorkflowTaskExecutor()
                let results = Box(value: Mutex([Int]()))
                await withTaskGroup(of: Void.self) { group in
                    group.addTask(executorPreference: executor) {
                        results.value.withLock { $0.append(1) }
                        await TemporalTestKit.blackHole(1)
                        results.value.withLock { $0.append(1) }
                        await TemporalTestKit.blackHole(2)
                        results.value.withLock { $0.append(1) }
                    }
                    group.addTask(executorPreference: executor) {
                        results.value.withLock { $0.append(2) }
                        await TemporalTestKit.blackHole(3)
                        results.value.withLock { $0.append(2) }
                        await TemporalTestKit.blackHole(4)
                        results.value.withLock { $0.append(2) }
                    }
                    group.addTask(executorPreference: executor) {
                        results.value.withLock { $0.append(3) }
                        await TemporalTestKit.blackHole(5)
                        results.value.withLock { $0.append(3) }
                        await TemporalTestKit.blackHole(6)
                        results.value.withLock { $0.append(3) }
                    }
                    executor.run()
                    await group.waitForAll()
                    #expect(results.value.withLock { $0 } == [1, 1, 1, 2, 2, 2, 3, 3, 3])
                }
            }
        }
    }
}
