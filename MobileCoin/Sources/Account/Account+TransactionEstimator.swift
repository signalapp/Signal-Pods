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
            logger.info("")
            self.account = account
            self.txOutSelector = TxOutSelector(txOutSelectionStrategy: txOutSelectionStrategy)
        }

        func amountTransferable(feeLevel: FeeLevel)
            -> Result<UInt64, BalanceTransferEstimationError>
        {
            logger.info("feeLevel: \(feeLevel)")
            let txOuts = account.readSync { $0.unspentTxOuts }
            return txOutSelector.amountTransferable(feeLevel: feeLevel, txOuts: txOuts)
        }

        func estimateTotalFee(toSendAmount amount: UInt64, feeLevel: FeeLevel)
            -> Result<UInt64, TransactionEstimationError>
        {
            logger.info("toSendAmount: \(redacting: amount), feeLevel: \(feeLevel)")
            guard amount > 0 else {
                logger.info("failure - Cannot spend 0 MOB")
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
            logger.info("toSendAmount: \(redacting: amount), feeLevel: \(feeLevel)")
            guard amount > 0 else {
                logger.info("failure - Cannot spend 0 MOB")
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
