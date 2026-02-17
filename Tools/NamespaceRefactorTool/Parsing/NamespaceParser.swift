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

struct NamespaceParser {
    /// Parses an underscore-separated type name into namespace components and a short name.
    ///
    /// Rules:
    /// - Split by underscore
    /// - Last component is the type name
    /// - All preceding components form the namespace
    /// - Skip redundant "Temporal" prefix (module is already named Temporal)
    ///
    /// Examples:
    /// - "Temporal_Api_Activity_V1_ActivityOptions" -> namespace: ["Api", "Activity", "V1"], name: "ActivityOptions"
    /// - "Coresdk_ActivityResult_Success" -> namespace: ["Coresdk", "ActivityResult"], name: "Success"
    static func parse(typeName: String) -> (namespace: [String], shortName: String)? {
        let components = typeName.split(separator: "_").map(String.init)

        guard components.count >= 2 else {
            // Need at least a namespace and a type name
            return nil
        }

        var namespace = Array(components.dropLast())
        let shortName = components.last!

        // Skip redundant "Temporal" prefix - module is already named Temporal
        if namespace.first?.lowercased() == "temporal" {
            namespace.removeFirst()
        }

        return (namespace: namespace, shortName: shortName)
    }
}
