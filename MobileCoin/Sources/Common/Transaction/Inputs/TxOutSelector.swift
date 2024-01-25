//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation

enum AmountTransferableError: Error {
    case feeExceedsBalance(String = String())
    case balanceOverflow(String = String())
}

extension AmountTransferableError: CustomStringConvertible {
    var description: String {
        "Amount transferable error: " + {
            switch self {
            case .feeExceedsBalance(let reason):
                return "Fee exceeds balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .balanceOverflow(let reason):
                return "Balance overflow\(!reason.isEmpty ? ": \(reason)" : "")"
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

final class TxOutSelector {
    private let txOutSelectionStrategy: TxOutSelectionStrategy

    init(txOutSelectionStrategy: TxOutSelectionStrategy) {
        self.txOutSelectionStrategy = txOutSelectionStrategy
    }

    func amountTransferable(tokenId: TokenId, feeStrategy: FeeStrategy, txOuts: [KnownTxOut])
        -> Result<UInt64, AmountTransferableError>
    {
        txOutSelectionStrategy.amountTransferable(
            tokenId: tokenId,
            feeStrategy: feeStrategy,
            txOuts: txOuts.map(SelectionTxOut.init))
    }

    func estimateTotalFee(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        txOuts: [KnownTxOut]
    ) -> Result<(totalFee: UInt64, requiresDefrag: Bool), TxOutSelectionError> {
        txOutSelectionStrategy.estimateTotalFee(
            toSendAmount: amount,
            feeStrategy: feeStrategy,
            txOuts: txOuts.map(SelectionTxOut.init))
    }

    func selectTransactionInputs(
        amount: Amount,
        fee: UInt64,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<[KnownTxOut], TransactionInputSelectionError> {
        txOutSelectionStrategy.selectTransactionInputs(
            amount: amount,
            fee: fee,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { $0.map { txOuts[$0] } }
    }

    func selectTransactionInput(
        amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<(inputs: [KnownTxOut], fee: UInt64), TransactionInputSelectionError> {
        txOutSelectionStrategy.selectTransactionInput(
            amount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { (inputs: $0.inputIds.map { txOuts[$0] }, fee: $0.fee) }
    }

    func selectTransactionInput(
        amount: Amount,
        fee: UInt64,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<[KnownTxOut], TransactionInputSelectionError> {
        txOutSelectionStrategy.selectTransactionInput(
            amount: amount,
            fee: fee,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { $0.map { txOuts[$0] } }
    }

    func selectTransactionInputs(
        amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<(inputs: [KnownTxOut], fee: UInt64), TransactionInputSelectionError> {
        txOutSelectionStrategy.selectTransactionInputs(
            amount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts.map(SelectionTxOut.init)
        ).map { (inputs: $0.inputIds.map { txOuts[$0] }, fee: $0.fee) }
    }

    func selectInputsForDefragTransactions(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [KnownTxOut]
    ) -> Result<[(inputs: [KnownTxOut], fee: UInt64)], TxOutSelectionError> {
        txOutSelectionStrategy.selectInputsForDefragTransactions(
            toSendAmount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts.enumerated().map(SelectionTxOut.init)
        ).map { defragTransactions in
            defragTransactions.map { (inputs: $0.inputIds.map { txOuts[$0] }, fee: $0.fee) }
        }
    }
}
