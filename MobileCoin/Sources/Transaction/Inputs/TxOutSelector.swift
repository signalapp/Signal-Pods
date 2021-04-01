//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation

enum TransactionInputSelectionError: Error {
    case insufficientTxOuts(String = String())
    case defragmentationRequired(String = String())
}

extension TransactionInputSelectionError: CustomStringConvertible {
    var description: String {
        "Transaction input selection error: " + {
            switch self {
            case .insufficientTxOuts(let reason):
                return "Insufficient TxOuts\(!reason.isEmpty ? ": \(reason)" : "")"
            case .defragmentationRequired(let reason):
                return "Defragmentation required\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

enum TxOutSelectionError: Error {
    case insufficientTxOuts(String = String())
}

extension TxOutSelectionError: CustomStringConvertible {
    var description: String {
        "TxOut selection error: " + {
            switch self {
            case .insufficientTxOuts(let reason):
                return "Insufficient TxOuts\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

final class TxOutSelector {
    private let txOutSelectionStrategy: TxOutSelectionStrategy

    init(txOutSelectionStrategy: TxOutSelectionStrategy) {
        logger.info("")
        self.txOutSelectionStrategy = txOutSelectionStrategy
    }

    func amountTransferable(feeLevel: FeeLevel, txOuts: [KnownTxOut])
        -> Result<UInt64, BalanceTransferEstimationError>
    {
        logger.info("")
        return txOutSelectionStrategy.amountTransferable(
            feeLevel: feeLevel,
            txOuts: txOuts.map(SelectionTxOut.init))
    }

    func estimateTotalFee(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel,
        txOuts: [KnownTxOut]
    ) -> Result<(totalFee: UInt64, requiresDefrag: Bool), TxOutSelectionError> {
        logger.info("")
        return txOutSelectionStrategy.estimateTotalFee(
            toSendAmount: amount,
            feeLevel: feeLevel,
            txOuts: txOuts.map(SelectionTxOut.init))
    }

    func selectTransactionInputs(
        amount: UInt64,
        fee: UInt64,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<[KnownTxOut], TransactionInputSelectionError> {
        logger.info("")
        return txOutSelectionStrategy.selectTransactionInputs(
            amount: amount,
            fee: fee,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { $0.map { txOuts[$0] } }
    }

    func selectTransactionInputs(
        amount: UInt64,
        feeLevel: FeeLevel,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<(inputs: [KnownTxOut], fee: UInt64), TransactionInputSelectionError> {
        logger.info("")
        return txOutSelectionStrategy.selectTransactionInputs(
            amount: amount,
            feeLevel: feeLevel,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { (inputs: $0.inputIds.map { txOuts[$0] }, fee: $0.fee) }
    }

    func selectInputsForDefragTransactions(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<[(inputs: [KnownTxOut], fee: UInt64)], TxOutSelectionError> {
        logger.info("")
        return txOutSelectionStrategy.selectInputsForDefragTransactions(
            toSendAmount: amount,
            feeLevel: feeLevel,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { defragTransactions in
            defragTransactions.map { (inputs: $0.inputIds.map { txOuts[$0] }, fee: $0.fee) }
        }
    }
}
