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

import Foundation
import SwiftASN1
import X509

enum TestData {
    static let certificateChain: [Certificate]? = {
        let certificateChainEnvironment = ProcessInfo.processInfo.environment["CERTIFICATE_CHAIN"]
        let certificateChainBuildSecret: String? = {
            guard let buildSecretsPath = ProcessInfo.processInfo.environment["BUILD_SECRETS_PATH"] else {
                return nil
            }
            let data = try! Data(contentsOf: URL(fileURLWithPath: "\(buildSecretsPath)/CERTIFICATE_CHAIN"))
            return String(data: data, encoding: .utf8)
        }()

        guard let certificateChain = certificateChainEnvironment ?? certificateChainBuildSecret else {
            return nil
        }

        return try! PEMDocument.parseMultiple(pemString: certificateChain).map { try! Certificate(pemDocument: $0) }
    }()

    static let privateKey: Certificate.PrivateKey? = {
        let privateKeyEnvironment = ProcessInfo.processInfo.environment["PRIVATE_KEY"]
        let privateKeyBuildSecret: String? = {
            guard let buildSecretsPath = ProcessInfo.processInfo.environment["BUILD_SECRETS_PATH"] else {
                return nil
            }
            let data = try! Data(contentsOf: URL(fileURLWithPath: "\(buildSecretsPath)/PRIVATE_KEY"))
            return String(data: data, encoding: .utf8)
        }()
        guard let privateKey = privateKeyEnvironment ?? privateKeyBuildSecret else {
            return nil
        }

        return try! .init(pemDocument: PEMDocument(pemString: privateKey))
    }()
}
