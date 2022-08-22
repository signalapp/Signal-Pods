//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// Provides a snapshot of account activity at a particular point in the ledger, as indicated by
/// `blockCount`.
/// `nil` tokenId means its a mixed set of transactions.
/// `.some` tokenId means all OwnedTxOut's have the same tokenId
public struct AccountActivity {
    public let txOuts: Set<OwnedTxOut>
    public let blockCount: UInt64
    public let tokenId: TokenId?

    init(txOuts: [OwnedTxOut], blockCount: UInt64, tokenId: TokenId? = nil) {
        self.txOuts = Set(txOuts)
        self.blockCount = blockCount
        self.tokenId = tokenId
    }
}
