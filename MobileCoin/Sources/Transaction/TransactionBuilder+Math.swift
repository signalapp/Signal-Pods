//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension TransactionBuilder {
    enum Math {}
}

extension TransactionBuilder.Math {

    static func totalOutlayCheck(
        for possibleTransaction: PossibleTransaction,
        fee: Amount,
        inputs: [PreparedTxInput],
        presignedInput: SignedContingentInput?
    ) -> Bool {
        guard let sci = presignedInput else {
            return totalOutlayCheck(for: possibleTransaction, fee: fee, inputs: inputs)
        }

        // for SCI:
        //
        // - input is meant to satisfy the required amount
        // - the required amount is an output added automatically by the sci builder in mobilecoin
        //
        // so, for this check, we just need to verify that:
        // presignedInput.requiredAmount + change amount = sum(inputs)
        return UInt64.safeCompare(
            sumOfValues: [sci.requiredAmount.value, possibleTransaction.changeAmount.value],
            isEqualToSumOfValues: inputs.map { $0.knownTxOut.value })
    }

    static func totalOutlayCheck(
        for possibleTransaction: PossibleTransaction,
        fee: Amount,
        inputs: [PreparedTxInput]
    ) -> Bool {
        let outputs = possibleTransaction.outputs
        let changeAmount = possibleTransaction.changeAmount
        let allValues = (outputs.map { $0.amount.value } + [fee.value, changeAmount.value])
        return UInt64.safeCompare(
                    sumOfValues: inputs.map { $0.knownTxOut.value },
                    isEqualToSumOfValues: allValues)
    }

    static func remainingAmount(
        inputValues: [UInt64],
        outputValues: [UInt64],
        fee: Amount
    ) -> Result<UInt64, TransactionBuilderError> {
        guard UInt64.safeCompare(
                sumOfValues: inputValues,
                isGreaterThanOrEqualToSumOfValues: outputValues + [fee.value])
        else {
            return .failure(.invalidInput("Total input amount < total output amount + fee"))
        }

        guard let remainingAmount = UInt64.safeSubtract(
                sumOfValues: inputValues,
                minusSumOfValues: outputValues + [fee.value])
        else {
            return .failure(.invalidInput("Change amount overflows UInt64"))
        }

        return .success(remainingAmount)
    }

    static func positiveRemainingAmount(
        inputValues: [UInt64],
        fee: Amount
    ) -> Result<PositiveUInt64, TransactionBuilderError> {
        guard UInt64.safeCompare(sumOfValues: inputValues, isGreaterThanValue: fee.value) else {
            return .failure(.invalidInput("Total input amount <= fee"))
        }

        guard let remainingAmount = UInt64.safeSubtract(
                sumOfValues: inputValues,
                minusValue: fee.value)
        else {
            return .failure(.invalidInput("Change amount overflows UInt64"))
        }

        guard let positiveRemainingAmount = PositiveUInt64(remainingAmount) else {
            // This condition should be redundant with the first check, but we throw an error
            // anyway, rather than calling fatalError.
            return .failure(.invalidInput("Total input amount == fee"))
        }

        return .success(positiveRemainingAmount)
    }

    static func positiveRemainingAmount(
        inputAmounts: [Amount],
        fee: Amount
    ) -> Result<Amount, TransactionBuilderError> {
        let inputTokenIdValues: Set<UInt64> = Set(inputAmounts.map { $0.tokenId.value })
        guard inputTokenIdValues.count == 1 else {
            return .failure(.invalidInput("Amounts must be of same tokenId"))
        }

        guard let tokenIdValue = inputTokenIdValues.first, fee.tokenId.value == tokenIdValue else {
            return .failure(.invalidInput("Amounts and fee must be of same tokenId"))
        }

        guard let tokenId = inputAmounts.first?.tokenId else {
            return .failure(.invalidInput("There must be at least one input"))
        }

        let inputValues = inputAmounts.map { $0.value }
        guard UInt64.safeCompare(
                sumOfValues: inputValues, isGreaterThanValue: fee.value) else {
            return .failure(.invalidInput("Total input amount <= fee"))
        }

        guard let remainingAmount = UInt64.safeSubtract(
                sumOfValues: inputValues,
                minusValue: fee.value)
        else {
            return .failure(.invalidInput("Change amount overflows UInt64"))
        }

        guard let positiveRemainingAmount = PositiveUInt64(remainingAmount) else {
            // This condition should be redundant with the first check, but we throw an error
            // anyway, rather than calling fatalError.
            return .failure(.invalidInput("Total input amount == fee"))
        }

        return .success(Amount(positiveRemainingAmount.value, in: tokenId))
    }

}
