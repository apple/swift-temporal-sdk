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

import Foundation
import SwiftParser
import SwiftSyntax

// This tool transforms the underscored proto generated namespaces into dot seperated ones.
// Ideally this would be part of SwiftProtobuf but the generation pattern has some problems discussed in
// https://github.com/apple/swift-protobuf/pull/1980.
@main
struct NamespaceRefactorTool {
    enum NameSpaceRefactorError: Error {
        case failedToIterateDictionary
    }
    static func main() {
        guard CommandLine.arguments.count >= 2 else {
            print("Usage: NamespaceRefactorTool <input_directory>")
            exit(1)
        }

        let inputDirectory = CommandLine.arguments[1]
        let inputURL = URL(fileURLWithPath: inputDirectory)

        print("Namespace Refactoring Tool")
        print("Input directory: \(inputDirectory)")
        print()

        do {
            try execute(inputDirectory: inputURL)
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }

    static func execute(inputDirectory: URL) throws {
        // Phase 1: Discover all types
        print("Phase 1: Discovering types...")
        let typeRegistry = TypeRegistry()
        let protoFiles = try findProtoFiles(in: inputDirectory)

        print("Found \(protoFiles.count) proto files")

        for file in protoFiles {
            try discoverTypes(in: file, registry: typeRegistry)
        }

        let allTypes = typeRegistry.allTypes()
        print("Discovered \(allTypes.count) types")
        print()

        // Phase 2: Generate Namespaces.swift
        print("Phase 2: Generating Namespaces.swift...")
        let generator = NamespacesGenerator(typeRegistry: typeRegistry)
        generator.buildTree()
        let namespacesContent = generator.generateNamespacesFile()

        let namespacesPath = inputDirectory.appendingPathComponent("Namespaces.swift")
        try namespacesContent.write(to: namespacesPath, atomically: true, encoding: .utf8)
        print("Generated: \(namespacesPath.path)")
        print()

        // Phase 3: Transform all files
        print("Phase 3: Transforming files...")
        for file in protoFiles {
            try transformFile(file, typeRegistry: typeRegistry)
            print("Transformed: \(file.lastPathComponent)")
        }

        // Phase 4: Update references in non-proto Swift files
        print()
        print("Phase 4: Updating references in client code...")
        let allSwiftFiles = try findAllSwiftFiles(in: inputDirectory)
        let nonProtoFiles = allSwiftFiles.filter { file in
            !protoFiles.contains(file) && file.lastPathComponent != "Namespaces.swift"
        }

        for file in nonProtoFiles {
            try transformFile(file, typeRegistry: typeRegistry)
            print("Updated: \(file.lastPathComponent)")
        }

        print()
        print("✓ Done! Transformed \(protoFiles.count) proto files and updated \(nonProtoFiles.count) client files")
    }

    static func findProtoFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw NameSpaceRefactorError.failedToIterateDictionary
        }

        var protoFiles: [URL] = []
        for case let fileURL as URL in enumerator {
            let filename = fileURL.lastPathComponent
            if filename.hasSuffix(".pb.swift") || filename.hasSuffix(".grpc.swift") {
                protoFiles.append(fileURL)
            }
        }

        return protoFiles.sorted { $0.path < $1.path }
    }

    static func findAllSwiftFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            throw NameSpaceRefactorError.failedToIterateDictionary
        }

        var swiftFiles: [URL] = []
        for case let fileURL as URL in enumerator {
            let filename = fileURL.lastPathComponent
            if filename.hasSuffix(".swift") {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles.sorted { $0.path < $1.path }
    }

    static func discoverTypes(in fileURL: URL, registry: TypeRegistry) throws {
        let source = try String(contentsOf: fileURL, encoding: .utf8)
        let syntax = Parser.parse(source: source)

        let visitor = TypeDiscoveryVisitor(filePath: fileURL.path)
        visitor.walk(syntax)

        for typeInfo in visitor.discoveredTypes {
            registry.register(typeInfo)
        }
    }

    static func transformFile(_ fileURL: URL, typeRegistry: TypeRegistry) throws {
        let source = try String(contentsOf: fileURL, encoding: .utf8)

        // Apply transformations using the hybrid approach
        let rewriter = NamespaceRewriter(typeRegistry: typeRegistry)
        let transformedSource = rewriter.transform(source: source)

        // Write back to file
        try transformedSource.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
