//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable file_length function_body_length function_parameter_count
// swiftlint:disable multiline_function_chains type_body_length

import Foundation

private enum SelectionFeeLevel {
    case feeStrategy(FeeStrategy)
    case fixedPerTransaction(UInt64)
}

struct DefaultTxOutSelectionStrategy: TxOutSelectionStrategy {
    func amountTransferable(
        feeStrategy: FeeStrategy,
        txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<UInt64, AmountTransferableError> {
        let txOutValues = txOuts.map { $0.value }
        if txOutValues.allSatisfy({ $0 == 0 }) {
            logger.info("Calculating amountTransferable with 0 balance", logFunction: false)
            return .success(0)
        }

        let totalFee = self.totalFee(
            numTxOuts: txOuts.count,
            selectionFeeLevel: .feeStrategy(feeStrategy),
            maxInputsPerTransaction: maxInputsPerTransaction)

        guard UInt64.safeCompare(sumOfValues: txOutValues, isGreaterThanValue: totalFee) else {
            logger.warning(
                "amountTransferable: Fee is equal to or greater than balance. txOut values: " +
                    "\(redacting: txOutValues), totalFee: \(redacting: totalFee)",
                logFunction: false)
            return .failure(.feeExceedsBalance())
        }

        guard let transferAmount =
                UInt64.safeSubtract(sumOfValues: txOutValues, minusValue: totalFee)
        else {
            logger.error(
                "amountTransferable failure: Balance minus fee exceeds UInt64.max. txOut values: " +
                    "\(redacting: txOutValues), totalFee: \(redacting: totalFee)",
                logFunction: false)
            return .failure(.balanceOverflow())
        }

        return .success(transferAmount)
    }

    func estimateTotalFee(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<(totalFee: UInt64, requiresDefrag: Bool), TxOutSelectionError> {
        estimateTotalFee(
            toSendAmount: amount,
            selectionFeeLevel: .feeStrategy(feeStrategy),
            txOuts: txOuts,
            maxInputsPerTransaction: maxInputsPerTransaction)
    }

    func selectTransactionInputs(
        amount: Amount,
        fee: UInt64,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputs: Int
    ) -> Result<[Int], TransactionInputSelectionError> {
        selectTransactionInputs(
            amount: amount,
            selectionFeeLevel: .fixedPerTransaction(fee),
            fromTxOuts: txOuts,
            maxInputs: maxInputs
        ).map { $0.inputIds }
    }

    func selectTransactionInputs(
        amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputs: Int
    ) -> Result<(inputIds: [Int], fee: UInt64), TransactionInputSelectionError> {
        selectTransactionInputs(
            amount: amount,
            selectionFeeLevel: .feeStrategy(feeStrategy),
            fromTxOuts: txOuts,
            maxInputs: maxInputs)
    }

    fileprivate func selectTransactionInputs(
        amount: Amount,
        selectionFeeLevel: SelectionFeeLevel,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputs: Int
    ) -> Result<(inputIds: [Int], fee: UInt64), TransactionInputSelectionError> {
        estimateTotalFee(
            toSendAmount: amount,
            selectionFeeLevel: selectionFeeLevel,
            txOuts: txOuts,
            maxInputsPerTransaction: maxInputs
        ).mapError {
            switch $0 {
            case .insufficientTxOuts:
                return .insufficientTxOuts()
            }
        }.flatMap {
            guard !$0.requiresDefrag else {
                logger.error(
                    "Transaction input selection failed: defragmentation required. amount: " +
                        "\(redacting: amount), txOut values: \(redacting: txOuts.map { $0.value })",
                    logFunction: false)
                return .failure(.defragmentationRequired())
            }

            return selectTxOuts(
                toSendAmount: amount,
                selectionFeeLevel: selectionFeeLevel,
                fromTxOuts: txOuts,
                maxInputsPerTransaction: maxInputs,
                maxTotalFee: $0.totalFee,
                allowDefrag: false
            ).mapError {
                switch $0 {
                case .insufficientTxOuts:
                    return .insufficientTxOuts()
                }
            }.map { ($0.txOutIds, $0.totalFee) }
        }
    }

    fileprivate func selectTxOuts(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<(txOutIds: [Int], totalFee: UInt64), TxOutSelectionError> {
        estimateTotalFee(
            toSendAmount: amount,
            selectionFeeLevel: .feeStrategy(feeStrategy),
            txOuts: txOuts,
            maxInputsPerTransaction: maxInputsPerTransaction
        ).flatMap {
            selectTxOuts(
                toSendAmount: amount,
                selectionFeeLevel: .feeStrategy(feeStrategy),
                fromTxOuts: txOuts,
                maxInputsPerTransaction: maxInputsPerTransaction,
                maxTotalFee: $0.totalFee,
                allowDefrag: true)
        }
    }

    /// Estimates the total amount of fees needed in order to send the specified amount, including
    /// the fees for any requisite defragmentation transactions.
    fileprivate func estimateTotalFee(
        toSendAmount amount: Amount,
        selectionFeeLevel: SelectionFeeLevel,
        txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<(totalFee: UInt64, requiresDefrag: Bool), TxOutSelectionError> {
        // Ensure that amount + fee is non-zero so that we select at least 1 input.
        let amount = amount.value != 0 || !selectionFeeLevel.isZeroFee ? amount.value : 1
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))

        // Sort by ascending value, skipping TxOuts with a value of 0.
        var availableTxOuts = txOuts.enumerated().map { ($0.offset, $0.element) }
            .filter { $0.1.value > 0 }
            .sorted { $0.1.value < $1.1.value }

        // We're simply estimating the fees required in the best case scenario, which means we want
        // to determine the fewest TxOuts we can select in order to send the specified amount. To do
        // this we incrementally select the highest value TxOuts until we either surpass the
        // requested amount + fees or we run out of available TxOuts to select.
        var selectedTxOuts: [(Int, SelectionTxOut)] = []
        while !availableTxOuts.isEmpty {
            // Defrag requires allowing at least 2 inputs per transaction.
            if maxInputsPerTransaction < 2 {
                // maxInputsPerTransaction is too low to perform defrag, so we are limited to 1
                // transaction total.
                guard selectedTxOuts.count < maxInputsPerTransaction else {
                    break
                }
            }

            // Select TxOut with next largest value from availableTxOuts.
            selectedTxOuts.append(availableTxOuts.removeLast())

            let totalFee = self.totalFee(
                numTxOuts: selectedTxOuts.count,
                selectionFeeLevel: selectionFeeLevel,
                maxInputsPerTransaction: maxInputsPerTransaction)
            // Use safeCompare in case summing the input values would overflow UInt64.max.
            if UInt64.safeCompare(
                sumOfValues: selectedTxOuts.map { $0.1.value },
                isGreaterThanOrEqualToSumOfValues: [amount, totalFee])
            {
                // Success! Sum value of selectedTxOuts is enough to cover sendAmount + totalFee.
                let requiresDefrag = selectedTxOuts.count > maxInputsPerTransaction
                return .success((totalFee, requiresDefrag))
            }
        }

        // Insufficient balance to cover sendAmount + the cost of any required defragmentation.
        logger.error(
            "Estimate total fee failed: insufficient TxOuts. amountToSend: \(redacting: amount), " +
                "txOut values: \(redacting: txOuts.map { $0.value })",
            logFunction: false)
        return .failure(.insufficientTxOuts())
    }

    /// Selects the optimal TxOuts from the given set of TxOuts, ensuring that they add up to at
    /// the specified amount and any fees required to send that amount. If `allowDefrag` is true,
    /// then the selectedTxOuts will not be bounded by the maximum number of inputs per transaction,
    /// and may require defragmentation steps in order to send all the TxOuts selected.
    fileprivate func selectTxOuts(
        toSendAmount amount: Amount,
        selectionFeeLevel: SelectionFeeLevel,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int,
        maxTotalFee: UInt64,
        allowDefrag: Bool
    ) -> Result<(txOutIds: [Int], totalFee: UInt64), TxOutSelectionError> {
        // Ensure that amount + fee is non-zero so that we select at least 1 input.
        let amountValue = amount.value != 0 || !selectionFeeLevel.isZeroFee ? amount.value : 1
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))

        // Sort by descending blockIndex then descending value, skipping TxOuts with a value of 0.
        var availableTxOuts = txOuts.enumerated().map { ($0.offset, $0.element) }
            .filter { $0.1.value > 0 }
            .sorted { decBlockIndexThenDecValue($0.1, $1.1) }

        var selectedTxOuts: [(Int, SelectionTxOut)] = []

        // First, incrementally select TxOuts based on oldest and lowest value first, in that order.
        //
        // Keep selecting until we can't select any more TxOuts, either because allowDefrag is false
        // and we've hit the max inputs per transaction or because adding an additional input would
        // increase the total fee, e.g. if it would require an additional defrag transaction.
        //
        // Once we can't slect any more TxOuts, then we iteratively reselect them, continuing to
        // favor oldest and lowest value TxOuts, and incrementally selecting younger and higher
        // value ones until we hit an end condition of either by surpassing the requested amount +
        // fees or by running out of additional TxOuts to try.
        while true {
            guard !availableTxOuts.isEmpty else {
                // Insufficient balance to cover amount + fee.
                logger.error(
                    "Select TxOuts failed: insufficient TxOuts. amountToSend: " +
                        "\(redacting: amountValue), " +
                        "txOut values: \(redacting: txOuts.map { $0.value })",
                    logFunction: false)
                return .failure(.insufficientTxOuts())
            }

            let totalFeeWithAddedTxOut = self.totalFee(
                numTxOuts: selectedTxOuts.count + 1,
                selectionFeeLevel: selectionFeeLevel,
                maxInputsPerTransaction: maxInputsPerTransaction)

            // Check if we can select additional TxOuts, or if we need to swap out one that's
            // already selected.
            if ((allowDefrag && maxInputsPerTransaction >= 2)
                    || selectedTxOuts.count < maxInputsPerTransaction)
                && totalFeeWithAddedTxOut <= maxTotalFee
            {
                // Select TxOut with next smallest blockIndex from availableTxOuts.
                selectedTxOuts.append(availableTxOuts.removeLast())
            } else {
                // Determine the highest value of the available TxOuts. This helps us when
                // deselecting a currently selected TxOut to know when to stop iterating.
                guard let highestAvailableValue = availableTxOuts.map({ $0.1.value }).max(by: <)
                else {
                    // Safety: availableTxOuts is guaranteed to not be empty at this point.
                    logger.fatalError("Select TxOuts failure: availableTxOuts is empty")
                }

                // Deselect 1 of the currently selected TxOuts. We want to favor selecting the
                // oldest and then the lowest value, in that order, so we deselect the youngest
                // and highest value of the ones that are less value that the most valuable
                // remaining available TxOut. This lets us essentially select the next best TxOut,
                // iteratively, while ensuring each time we reselect we're increasing the overall
                // value of the currently selected TxOuts.
                guard let deselectedTxOut = selectedTxOuts.enumerated()
                        .filter({ $0.element.1.value < highestAvailableValue })
                        .min(by: { decBlockIndexThenDecValue($0.element.1, $1.element.1) })
                        .map({ selectedTxOuts.remove(at: $0.offset) })
                else {
                    // We've selected the highest value TxOuts already which means the TxOuts don't
                    // have enough total value to cover amount + fees.
                    logger.error(
                        "Select TxOuts failed: insufficient TxOuts. amountToSend: " +
                            "\(redacting: amount), txOut values: " +
                            "\(redacting: txOuts.map { $0.value })",
                        logFunction: false)
                    return .failure(.insufficientTxOuts())
                }

                // Select the next oldest and lowest value TxOut of the available TxOuts, making
                // sure we only choose ones of higher value than the one we just deselected.
                guard let selectedTxOut = availableTxOuts.enumerated()
                        .filter({ $0.element.1.value > deselectedTxOut.1.value })
                        .max(by: { decBlockIndexThenDecValue($0.element.1, $1.element.1) })
                        .map({ availableTxOuts.remove(at: $0.offset) })
                else {
                    // Safety: availableTxOuts is guaranteed to not be empty at this point and
                    // guaranteed to have a TxOut with a value greater the value of deselectedTxOut.
                    logger.fatalError("Select TxOuts failure: availableTxOuts is empty")
                }

                selectedTxOuts.append(selectedTxOut)

                // Return the deselected TxOut to the available TxOut pool since it might become the
                // highest remaining available TxOut in a later iteration of the while-loop.
                availableTxOuts.append(deselectedTxOut)
            }

            let totalFee = self.totalFee(
                numTxOuts: selectedTxOuts.count,
                selectionFeeLevel: selectionFeeLevel,
                maxInputsPerTransaction: maxInputsPerTransaction)

            // Use safeCompare in case summing the input values would overflow UInt64.max.
            if UInt64.safeCompare(
                sumOfValues: selectedTxOuts.map { $0.1.value },
                isGreaterThanOrEqualToSumOfValues: [amountValue, totalFee])
            {
                // Success! Sum value of selectedTxOuts is enough to cover amount + fee.
                break
            }
        }

        // Fill any open slots, as long as it doesn't increase the fee.
        fillFinalInputInputSlots(
            selectedTxOuts: &selectedTxOuts,
            availableTxOuts: &availableTxOuts,
            amountToSend: amount,
            selectionFeeLevel: selectionFeeLevel,
            maxInputsPerTransaction: maxInputsPerTransaction,
            maxTotalFee: maxTotalFee)

        let finalFee = totalFee(
            numTxOuts: selectedTxOuts.count,
            selectionFeeLevel: selectionFeeLevel,
            maxInputsPerTransaction: maxInputsPerTransaction)

        return .success((selectedTxOuts.map { $0.0 }, finalFee))
    }

    /// Selects the inputs to any defragmentation transactions that must be sent in order to
    /// ultimately send the specified amount. If no defragmentation is required, then an empty array
    /// is returns.
    func selectInputsForDefragTransactions(
        toSendAmount amount: Amount,
        feeStrategy: FeeStrategy,
        fromTxOuts txOuts: [SelectionTxOut],
        maxInputsPerTransaction: Int
    ) -> Result<[(inputIds: [Int], fee: UInt64)], TxOutSelectionError> {
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))
        guard maxInputsPerTransaction >= 2 else {
            // Can't perform defrag with less than 2 inputs.
            return .success([])
        }

        // Select the set of TxOuts we intend to use to send the specified amount. Note that some of
        // these might not be selected for inclusion as an input to a defragmentation transaction
        // and might be spent in a subsequent transaction instead (either a defragmentation
        // transaction in a later defragmentation step or in the final non-defragmentation
        // transaction).
        let allSelectedTxOuts: [SelectionTxOut]
        switch selectTxOuts(
            toSendAmount: amount,
            feeStrategy: feeStrategy,
            fromTxOuts: txOuts,
            maxInputsPerTransaction: maxInputsPerTransaction)
        {
        case .success(let (txOutIds: txOutIds, totalFee: _)):
            allSelectedTxOuts = txOutIds.map { txOuts[$0] }
        case .failure(let error):
            return .failure(error)
        }

        // Fee to send a single defrag transaction.
        let defragTransactionFee =
            feeStrategy.defragTransactionFee(maxInputs: maxInputsPerTransaction)

        var defragTransactions: [[(Int, SelectionTxOut)]] = []

        // Sort by ascending value then ascending blockIndex, skipping TxOuts with a value of 0.
        var availableTxOuts = allSelectedTxOuts.enumerated().map { ($0.offset, $0.element) }
            .filter { $0.1.value > 0 }
            .sorted { incValueThenIncBlockIndex($0.1, $1.1) }

        // Loop through availableTxOuts, stopping only when we know the remaining availableTxOuts +
        // the results of the defrag transactions don't cause an extra defrag when we could have
        // added that defrag in this step.
        //
        // E.g. Suppose we have 242 availableTxOuts to start with. If we have 15 defrag tx's this
        // step and 2 remaining availableTxOuts, if we defrag the 2 remaining txOuts in this round,
        // then we end up with 16 defrag tx's, yielding 16 outputs, which can be spent directly,
        // rather than needing further defrag'ing. However, if we only defrag 15 tx's this round,
        // then we end up with 17 outputs, which would require an addition round of defragging to
        // send the desired amount.
        //
        // Note: the reason we don't just defrag all availableTxOuts every round, is that this might
        // lead to performing unnecessary defrag tx's overall.
        while availableTxOuts.count + (defragTransactions.count % maxInputsPerTransaction)
                > maxInputsPerTransaction
        {
            var selectedHighValueTxOuts: [(Int, SelectionTxOut)] = []
            var selectedLowValueTxOuts: [(Int, SelectionTxOut)] = []
            while true {
                let numLowValueInputsToSelect = min(
                    maxInputsPerTransaction - selectedHighValueTxOuts.count,
                    availableTxOuts.count)
                selectedLowValueTxOuts = Array(availableTxOuts[..<numLowValueInputsToSelect])

                if UInt64.safeCompare(
                    sumOfValues:
                        (selectedHighValueTxOuts + selectedLowValueTxOuts).map { $0.1.value },
                    isGreaterThanOrEqualToValue: defragTransactionFee)
                {
                    availableTxOuts.removeFirst(numLowValueInputsToSelect)
                    break
                }

                guard selectedHighValueTxOuts.count < maxInputsPerTransaction
                        && !availableTxOuts.isEmpty
                else {
                    return .failure(.insufficientTxOuts())
                }

                // Select TxOut with next largest value from availableTxOuts.
                selectedHighValueTxOuts.append(availableTxOuts.removeLast())
            }
            defragTransactions.append(selectedHighValueTxOuts + selectedLowValueTxOuts)
        }
        return .success(
            defragTransactions.map {
                (inputIds: $0.compactMap { $0.1.inputIndex }, fee: defragTransactionFee)
            })
    }

    /// Selects additional TxOuts to fill the remaining input slots in the final transaction,
    /// while ensuring that the fee doesn't increase in the process. The final transaction is either
    /// the current transaction if no defragmentation is required, or if it is required, then the
    /// final transaction refers to the ultimate transaction that will be send after all
    /// necessary defragmentation is performed.
    ///
    /// The purpose of filling up all available input slots is to try and cut down on the amount of
    /// fragmentation that the account incurs in the first place, by rolling up small value TxOuts
    /// whenever it doesn't cost anything extra in fees to do so. This helps keep the number of
    /// unspent TxOuts in an account low, making it more likely that the user can send a transaction
    /// immediately without defragmentation.
    fileprivate func fillFinalInputInputSlots(
        selectedTxOuts: inout [(Int, SelectionTxOut)],
        availableTxOuts: inout [(Int, SelectionTxOut)],
        amountToSend: Amount,
        selectionFeeLevel: SelectionFeeLevel,
        maxInputsPerTransaction: Int,
        maxTotalFee: UInt64
    ) {
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))

        // Sort by descending blockIndex then descending value.
        availableTxOuts.sort { decBlockIndexThenDecValue($0.1, $1.1) }

        // Start by trying to fill up all extra slots, as long as it doesn't increase the total fee.
        // If it does increase the fee, decrease the number of added inputs and try again, stopping
        // if can't add any inputs without increasing the total fee.
        //
        // Fill using the smallest remaining TxOuts. We also make sure we're not blindly adding
        // a bunch of high value inputs that will overflow UInt64.max when we try to construct
        // the output (for defrag transactions) or the change output (for non-defragmentation
        // transactions). It's okay to be overly cautious here since already know we have enough
        // inputs to send the requested amount.

        let numOpenInputSlotsInFinalTransaction = maxInputsPerTransaction
            - numInputsInFinalTransaction(
                numSelected: selectedTxOuts.count,
                maxInputsPerTransaction: maxInputsPerTransaction)
        var numInputsToAdd = min(numOpenInputSlotsInFinalTransaction, availableTxOuts.count)
        var txOutsToAdd: [(Int, SelectionTxOut)] = []
        while true {
            guard numInputsToAdd > 0 else {
                return
            }

            let fee = totalFee(
                numTxOuts: selectedTxOuts.count + numInputsToAdd,
                selectionFeeLevel: selectionFeeLevel,
                maxInputsPerTransaction: maxInputsPerTransaction)
            txOutsToAdd = availableTxOuts.suffix(numInputsToAdd)
            if fee <= maxTotalFee
                && UInt64.safeCompare(
                    sumOfValues: (selectedTxOuts + txOutsToAdd).map { $0.1.value },
                    isLessThanOrEqualToSumOfValues: [amountToSend.value, fee, UInt64.max])
            {
                break
            }

            numInputsToAdd -= 1
        }

        guard !txOutsToAdd.isEmpty else {
            return
        }

        logger.info(
            "Dust cleanup: adding \(txOutsToAdd.count) inputs to transaction",
            logFunction: false)
        selectedTxOuts.append(contentsOf: txOutsToAdd)
        availableTxOuts.removeLast(txOutsToAdd.count)
    }

    func numDefragTransactions(numSelected: Int, maxInputsPerTransaction: Int) -> Int {
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))
        guard maxInputsPerTransaction >= 2 else {
            // Can't perform defrag with less than 2 inputs.
            return 0
        }

        return max((numSelected - 2) / (maxInputsPerTransaction - 1), 0)
    }

    func numInputsInFinalTransaction(numSelected: Int, maxInputsPerTransaction: Int) -> Int {
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))

        let numDefragTransactions = self.numDefragTransactions(
            numSelected: numSelected,
            maxInputsPerTransaction: maxInputsPerTransaction)
        let numNetDefragTxOuts = numDefragTransactions * (maxInputsPerTransaction - 1)
        return min(numSelected - numNetDefragTxOuts, maxInputsPerTransaction)
    }

    fileprivate func totalFee(
        numTxOuts: Int,
        selectionFeeLevel: SelectionFeeLevel,
        maxInputsPerTransaction: Int
    ) -> UInt64 {
        defragFees(
            numTxOuts: numTxOuts,
            selectionFeeLevel: selectionFeeLevel,
            maxInputsPerTransaction: maxInputsPerTransaction)
            + feeForFinalTransaction(
                numTxOuts: numTxOuts,
                selectionFeeLevel: selectionFeeLevel,
                maxInputsPerTransaction: maxInputsPerTransaction)
    }

    fileprivate func defragFees(
        numTxOuts: Int,
        selectionFeeLevel: SelectionFeeLevel,
        maxInputsPerTransaction: Int
    ) -> UInt64 {
        // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
        let maxInputsPerTransaction = max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))
        guard maxInputsPerTransaction >= 2 else {
            return 0
        }

        return UInt64(
            numDefragTransactions(
                numSelected: numTxOuts,
                maxInputsPerTransaction: maxInputsPerTransaction))
            * selectionFeeLevel.defragTransactionFee(maxInputs: maxInputsPerTransaction)
    }

    fileprivate func feeForFinalTransaction(
        numTxOuts: Int,
        selectionFeeLevel: SelectionFeeLevel,
        maxInputsPerTransaction: Int
    ) -> UInt64 {
        switch selectionFeeLevel {
        case .feeStrategy(let feeStrategy):
            // Clamp maxInputs between 1 and McConstants.MAX_INPUTS, inclusive.
            let maxInputsPerTransaction =
                max(1, min(maxInputsPerTransaction, McConstants.MAX_INPUTS))

            let numInputsInFinalTransaction = self.numInputsInFinalTransaction(
                numSelected: numTxOuts,
                maxInputsPerTransaction: maxInputsPerTransaction)
            return feeStrategy.fee(numInputs: numInputsInFinalTransaction, numOutputs: 2)
        case .fixedPerTransaction(let fee):
            return fee
        }
    }
}

extension FeeStrategy {
    /// Fee to send a single defrag transaction.
    func defragTransactionFee(maxInputs: Int) -> UInt64 {
        fee(numInputs: maxInputs, numOutputs: 1)
    }
}

extension SelectionFeeLevel {
    /// Fee to send a single defrag transaction.
    func defragTransactionFee(maxInputs: Int) -> UInt64 {
        switch self {
        case .feeStrategy(let feeStrategy):
            return feeStrategy.defragTransactionFee(maxInputs: maxInputs)
        case .fixedPerTransaction(let fee):
            return fee
        }
    }
}

extension SelectionFeeLevel {
    fileprivate var isZeroFee: Bool {
        if case .fixedPerTransaction(0) = self {
            return true
        } else {
            return false
        }
    }
}

// Return true if a is lesser in value, or if they're equal in value, then return true if a is older
// in the ledger (lower blockIndex).
private func incValueThenIncBlockIndex(_ a: SelectionTxOut, _ b: SelectionTxOut) -> Bool {
    a.value < b.value || (a.value == b.value && a.blockIndex < b.blockIndex)
}

// Return true if a is newer in the ledger (higher blockIndex), or if they appeared in the same
// block, then return true if a is greater in value.
private func decBlockIndexThenDecValue(_ a: SelectionTxOut, _ b: SelectionTxOut) -> Bool {
    a.blockIndex > b.blockIndex || (a.blockIndex == b.blockIndex && a.value > b.value)
}
