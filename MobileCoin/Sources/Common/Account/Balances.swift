//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct Balances {
    public let balances: [TokenId: Balance]
    public var tokenIds: Set<TokenId> {
        Set(balances.keys)
    }

    public var mobBalance: Balance {
        guard let balance = balances[.MOB] else {
            return Balance(
                amountLow: 0,
                amountHigh: 0,
                blockCount: blockCount,
                tokenId: .MOB)
        }
        return balance
    }

    let blockCount: UInt64

    init(balances: [TokenId: Balance], blockCount: UInt64) {
        self.balances = balances
        self.blockCount = blockCount
    }
}

extension Balances: CustomStringConvertible {
    public var description: String {
        "Balances: " + balances.values.map({ $0.description }).joined(separator: ", ")
    }
}
