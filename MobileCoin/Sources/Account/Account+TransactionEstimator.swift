//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Account {
    struct TransactionEstimator {
        private let account: ReadWriteDispatchLock<Account>
        private let txOutSelector: TxOutSelector

        init(
            account: ReadWriteDispatchLock<Account>,
            txOutSelectionStrategy: TxOutSelectionStrategy
        ) {
            self.account = account
            self.txOutSelector = TxOutSelector(txOutSelectionStrategy: txOutSelectionStrategy)
        }

        func amountTransferable(feeLevel: FeeLevel)
            -> Result<UInt64, BalanceTransferEstimationError>
        {
            let txOuts = account.readSync { $0.unspentTxOuts }
            return txOutSelector.amountTransferable(feeLevel: feeLevel, txOuts: txOuts)
        }

        func estimateTotalFee(toSendAmount amount: UInt64, feeLevel: FeeLevel)
            -> Result<UInt64, TransactionEstimationError>
        {
            guard amount > 0 else {
                return .failure(.invalidInput("Cannot spend 0 MOB"))
            }

            let txOuts = account.readSync { $0.unspentTxOuts }
            return txOutSelector
                .estimateTotalFee(toSendAmount: amount, feeLevel: feeLevel, txOuts: txOuts)
                .mapError { _ in .insufficientBalance() }
                .map { $0.totalFee }
        }

        func requiresDefragmentation(toSendAmount amount: UInt64, feeLevel: FeeLevel)
            -> Result<Bool, TransactionEstimationError>
        {
            guard amount > 0 else {
                return .failure(.invalidInput("Cannot spend 0 MOB"))
            }

            let txOuts = account.readSync { $0.unspentTxOuts }
            return txOutSelector
                .estimateTotalFee(toSendAmount: amount, feeLevel: feeLevel, txOuts: txOuts)
                .mapError { _ in .insufficientBalance() }
                .map { $0.requiresDefrag }
        }
    }
}
