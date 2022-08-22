//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct SelectionTxOut {
    let value: UInt64
    let blockIndex: UInt64

    init(_ txOut: KnownTxOut) {
        self.init(value: txOut.value, blockIndex: txOut.block.index)
    }

    init(value: UInt64, blockIndex: UInt64) {
        self.value = value
        self.blockIndex = blockIndex
    }
}

protocol TxOutSelectionStrategy {
    func amountTransferable(
        feeStrategy: FeeStrategy,
        txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<UInt64, AmountTransferableError>

    func estimateTotalFee(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<(totalFee: UInt64, requiresDefrag: Bool), TxOutSelectionError>

    func selectTransactionInputs(
        amount: Amount,
        fee: UInt64,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputs: Int
    ) -> Result<[Int], TransactionInputSelectionError>

    func selectTransactionInputs(
        amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputs: Int
    ) -> Result<(inputIds: [Int], fee: UInt64), TransactionInputSelectionError>

    func selectInputsForDefragTransactions(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<[(inputIds: [Int], fee: UInt64)], TxOutSelectionError>
}

extension TxOutSelectionStrategy {
    func amountTransferable(tokenId: TokenId, feeStrategy: FeeStrategy, txOuts: [SelectionTxOut])
        -> Result<UInt64, AmountTransferableError>
    {
        amountTransferable(
            feeStrategy: feeStrategy,
            txOuts: txOuts,
            maxInputsPerTransaction: McConstants.MAX_INPUTS)
    }

    func estimateTotalFee(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        txOuts: [SelectionTxOut]
    ) -> Result<(totalFee: UInt64, requiresDefrag: Bool), TxOutSelectionError> {
        estimateTotalFee(
            toSendAmount: amount,
            feeStrategy: feeStrategy,
            txOuts: txOuts,
            maxInputsPerTransaction: McConstants.MAX_INPUTS)
    }

    func selectTransactionInputs(
        amount: Amount,
        fee: UInt64,
        fromTxOuts txOuts: [SelectionTxOut]
    ) -> Result<[Int], TransactionInputSelectionError> {
        selectTransactionInputs(
            amount: amount,
            fee: fee,
            fromTxOuts: txOuts,
            maxInputs: McConstants.MAX_INPUTS)
    }

    func selectTransactionInputs(
        amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut]
    ) -> Result<(inputIds: [Int], fee: UInt64), TransactionInputSelectionError> {
        selectTransactionInputs(
            amount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts,
            maxInputs: McConstants.MAX_INPUTS)
    }

    func selectInputsForDefragTransactions(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut]
    ) -> Result<[(inputIds: [Int], fee: UInt64)], TxOutSelectionError> {
        selectInputsForDefragTransactions(
            toSendAmount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts,
            maxInputsPerTransaction: McConstants.MAX_INPUTS)
    }
}
