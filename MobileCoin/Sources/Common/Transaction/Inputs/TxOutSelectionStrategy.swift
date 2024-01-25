//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable todo

import Foundation

struct SelectionTxOut {
    let value: UInt64
    let blockIndex: UInt64
    var inputIndex: Int?
    var knownTxOut: KnownTxOut?

    // TODO - might be better to use KnownTxOut public keys instead of "original index".
    // This is a workaround for now to get critical feature unblocked.

    init(_ txOut: KnownTxOut) {
        self.init(value: txOut.value, blockIndex: txOut.block.index, knownTxOut: txOut)
    }

    init(_ index: Int, _ txOut: KnownTxOut) {
        self.init(
            value: txOut.value,
            blockIndex: txOut.block.index,
            knownTxOut: txOut,
            inputIndex: index
        )
    }

    init(value: UInt64, blockIndex: UInt64, knownTxOut: KnownTxOut? = nil, inputIndex: Int? = nil) {
        self.value = value
        self.blockIndex = blockIndex
        self.knownTxOut = knownTxOut
        self.inputIndex = inputIndex
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

    func selectTransactionInput(
        amount: Amount,
        fee: UInt64,
        fromTxOuts txOuts: [SelectionTxOut]
    ) -> Result<[Int], TransactionInputSelectionError> {
        selectTransactionInputs(
            amount: amount,
            fee: fee,
            fromTxOuts: txOuts,
            maxInputs: 1)
    }

    func selectTransactionInput(
        amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut]
    ) -> Result<(inputIds: [Int], fee: UInt64), TransactionInputSelectionError> {
        selectTransactionInputs(
            amount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts,
            maxInputs: 1)
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
