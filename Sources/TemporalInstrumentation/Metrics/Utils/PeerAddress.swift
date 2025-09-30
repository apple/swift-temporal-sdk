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

enum PeerAddress: Equatable {
    case ipv4(address: String, port: Int?)
    case ipv6(address: String, port: Int?)
    case unixDomainSocket(path: String)

    package init?(_ address: String) {
        // We expect this address to be of one of these formats:
        // - ipv4:<host>:<port> for ipv4 addresses
        // - ipv6:[<host>]:<port> for ipv6 addresses
        // - unix:<uds-pathname> for UNIX domain sockets

        // First get the first component so that we know what type of address we're dealing with
        let addressComponents = address.split(separator: ":", maxSplits: 1)

        guard addressComponents.count > 1 else {
            // This is some unexpected/unknown format
            return nil
        }

        // Check what type the transport is...
        switch addressComponents[0] {
        case "ipv4":
            let ipv4AddressComponents = addressComponents[1].split(separator: ":")
            guard ipv4AddressComponents.count == 2, let port = Int(ipv4AddressComponents[1]) else {
                return nil
            }
            self = .ipv4(address: String(ipv4AddressComponents[0]), port: port)

        case "ipv6":
            guard addressComponents[1].first == "[" else {
                return nil
            }
            // At this point, we are looking at an address with format: [<address>]:<port>
            // We drop the first character ('[') and split by ']:' to keep two components: the address
            // and the port.
            let ipv6AddressComponents = addressComponents[1].dropFirst().split(separator: "]:")
            guard ipv6AddressComponents.count == 2, let port = Int(ipv6AddressComponents[1]) else {
                return nil
            }
            self = .ipv6(address: String(ipv6AddressComponents[0]), port: port)

        case "unix":
            // Whatever comes after "unix:" is the <pathname>
            self = .unixDomainSocket(path: String(addressComponents[1]))

        default:
            // This is some unexpected/unknown format
            return nil
        }
    }
}
