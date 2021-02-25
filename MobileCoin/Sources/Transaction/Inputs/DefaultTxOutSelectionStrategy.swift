//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable todo

import Foundation

final class DefaultTxOutSelectionStrategy: TxOutSelectionStrategy {
    func selectTxOuts(
        totalingAtLeast amount: UInt64,
        from txOuts: [KnownTxOut]
    ) throws -> [KnownTxOut] {
        var selectedTxOuts: [KnownTxOut] = []

        // TODO: Implement more intelligent TxOut selection
        var valueAccum: UInt64 = 0
        for txOut in txOuts {
            selectedTxOuts.append(txOut)
            valueAccum += txOut.value

            if valueAccum >= amount { break }
        }

        guard valueAccum >= amount else {
            throw MalformedInput("Amount exceeds sum of TxOuts. Amount: \(amount), " +
                "TxOuts: \(valueAccum)")
        }

        return selectedTxOuts
    }
}
