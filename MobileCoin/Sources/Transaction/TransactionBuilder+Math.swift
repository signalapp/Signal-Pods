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
        inputs: [PreparedTxInput]
    ) -> Bool {
        let outputs = possibleTransaction.outputs
        let changeAmount = possibleTransaction.changeAmount
        let allValues = (outputs.map { $0.amount.value } + [fee.value, changeAmount?.value ?? 0])
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

}
