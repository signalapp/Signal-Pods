//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// Wrapper type that holds a collection of `KnownTxOut`'s along with a `spendAmount`, with the sum
/// value of the `KnownTxOut`'s guaranteed to be greater than or equal to the value of
/// `spendAmount`.
struct SpendableTxOutsWithAmount {
    let txOuts: [KnownTxOut]
    let spendAmount: UInt64

    /// - Returns: `nil` when sum value of `txOuts` is less than `amount`.
    init?(_ txOuts: [KnownTxOut], totalingAtLeast amount: UInt64) {
        guard txOuts.map({ $0.value }).reduce(0, +) >= amount else {
            logger.info("total value of txOuts less than amount")
            return nil
        }
        self.txOuts = txOuts
        self.spendAmount = amount
    }
}
