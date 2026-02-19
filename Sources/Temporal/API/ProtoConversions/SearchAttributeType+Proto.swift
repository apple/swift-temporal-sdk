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

extension SearchAttributeType {
    init(_ indexedValueType: Api.Enums.V1.IndexedValueType) {
        self =
            switch indexedValueType {
            case .unspecified: .unspecified
            case .text: .text
            case .keyword: .keyword
            case .int: .int
            case .double: .double
            case .bool: .bool
            case .datetime: .dateTime
            case .keywordList: .keywordList
            case .UNRECOGNIZED(let value):
                fatalError("Unrecognized value when initializing SearchAttributeType: \(value)")
            }
    }

    init?(indexedValueTypeString: String) {
        let value: Self? =
            switch indexedValueTypeString {
            case "": .unspecified
            case "Text": .text
            case "Keyword": .keyword
            case "Int": .int
            case "Double": .double
            case "Bool": .bool
            case "Datetime": .dateTime
            case "KeywordList": .keywordList
            default: nil
            }
        guard let value else {
            return nil
        }
        self = value
    }

    var indexedValueTypeString: String {
        switch self {
        case .unspecified: ""
        case .text: "Text"
        case .keyword: "Keyword"
        case .int: "Int"
        case .double: "Double"
        case .bool: "Bool"
        case .dateTime: "Datetime"
        case .keywordList: "KeywordList"
        }
    }
}

extension Api.Enums.V1.IndexedValueType {
    init(_ type: SearchAttributeType) {
        self =
            switch type {
            case .unspecified: .unspecified
            case .text: .text
            case .keyword: .keyword
            case .int: .int
            case .double: .double
            case .bool: .bool
            case .dateTime: .datetime
            case .keywordList: .keywordList
            }
    }
}
