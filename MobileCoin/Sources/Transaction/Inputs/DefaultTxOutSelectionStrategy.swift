//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable todo

import Foundation

final class DefaultTxOutSelectionStrategy: TxOutSelectionStrategy {
    func selectTxOuts(_ txOuts: SpendableTxOutsWithAmount) -> SpendableTxOutsWithAmount {
        var selectedTxOuts: [KnownTxOut] = []

        // TODO: Implement more intelligent TxOut selection
        var valueAccum: UInt64 = 0
        for txOut in txOuts.txOuts {
            selectedTxOuts.append(txOut)
            valueAccum += txOut.value

            if valueAccum >= txOuts.spendAmount { break }
        }

        guard let selectedTxOutsWithAmount
                = SpendableTxOutsWithAmount(selectedTxOuts, totalingAtLeast: txOuts.spendAmount)
        else {
            // Safety: `selectedTxOuts` will always total at least `spendAmount`.
            logger.fatalError(
                "Error: \(Self.self).\(#function): selectedTxOuts less than spendAmount.")
        }

        return selectedTxOutsWithAmount
    }
}
