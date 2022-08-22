//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct TokenId {
    public let value: UInt64
    public var name: String {
        Self.names[self] ?? "TokenId \(self.value)"
    }

    public var significantDigits: UInt8 {
        Self.significantDigits[self] ?? 12
    }

    public var siPrefix: String? {
        SIDecimalPrefix(rawValue: significantDigits)?.name
    }

    public init(_ value: UInt64) {
        self.value = value
    }
}

extension TokenId {
    public static var MOB = TokenId(0)
    public static var MOBUSD = TokenId(1)
}

extension TokenId: CustomStringConvertible {
    public var description: String {
        self.name
    }

    static var names: [TokenId: String] = {
        [
            .MOB: "MOB",
            .MOBUSD: "MOBUSD",
        ]
    }()

    static var significantDigits: [TokenId: UInt8] = {
        [
            .MOB: 12,
            .MOBUSD: 6,
        ]
    }()
}

extension TokenId: Equatable, Hashable {}
