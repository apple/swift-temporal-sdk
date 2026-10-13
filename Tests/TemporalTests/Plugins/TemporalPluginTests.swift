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

import Temporal
import Testing

@Suite(.tags(.pluginTests))
struct TemporalPluginTests {
    /// Conforms to both plugin protocols without declaring `name`.
    ///
    /// If each protocol had its own defaulted `name`, this wouldn't compile ("multiple matching
    /// properties named 'name'"), so the type compiling at all is part of the test.
    private struct BothSidesPlugin: ClientPlugin, WorkerPlugin {}

    private struct NamedBothSidesPlugin: ClientPlugin, WorkerPlugin {
        let name = "my-org.named"
    }

    @Test
    func typeConformingToBothProtocolsInheritsOneDefaultName() {
        #expect(BothSidesPlugin().name == "BothSidesPlugin")
    }

    @Test
    func explicitNameWinsOverTheDefault() {
        #expect(NamedBothSidesPlugin().name == "my-org.named")
    }

    @Test
    func defaultNameIsReadableThroughEitherExistential() {
        let plugin = BothSidesPlugin()
        let asClient: any ClientPlugin = plugin
        let asWorker: any WorkerPlugin = plugin
        #expect(asClient.name == "BothSidesPlugin")
        #expect(asWorker.name == "BothSidesPlugin")
    }
}
