//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable closure_body_length function_body_length multiline_arguments type_body_length

import Foundation

extension Account {
    struct TransactionOperations {
        private let serialQueue: DispatchQueue
        private let account: ReadWriteDispatchLock<Account>
        private let metaFetcher: BlockchainMetaFetcher
        private let txOutSelector: TxOutSelector
        private let transactionPreparer: TransactionPreparer

        init(
            account: ReadWriteDispatchLock<Account>,
            fogMerkleProofService: FogMerkleProofService,
            fogResolverManager: FogResolverManager,
            metaFetcher: BlockchainMetaFetcher,
            txOutSelectionStrategy: TxOutSelectionStrategy,
            mixinSelectionStrategy: MixinSelectionStrategy,
            rngSeed: RngSeed,
            targetQueue: DispatchQueue?
        ) {
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(Account.self).\(Self.self))",
                target: targetQueue)
            self.account = account
            self.metaFetcher = metaFetcher
            self.txOutSelector = TxOutSelector(txOutSelectionStrategy: txOutSelectionStrategy)
            self.transactionPreparer = TransactionPreparer(
                accountKey: account.accessWithoutLocking.accountKey,
                fogMerkleProofService: fogMerkleProofService,
                fogResolverManager: fogResolverManager,
                mixinSelectionStrategy: mixinSelectionStrategy,
                rngSeed: rngSeed,
                targetQueue: targetQueue)
        }

        func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType,
            amount: Amount,
            fee: UInt64,
            completion: @escaping (
                Result<PendingSinglePayloadTransaction, TransactionPreparationError>
            ) -> Void
        ) {
            guard amount.value > 0 else {
                let errorMessage = "prepareTransactionWithFee failure: " +
                    "Cannot spend 0 \(amount.tokenId)"
                logger.error(errorMessage, logFunction: false)
                serialQueue.async {
                    completion(.failure(.invalidInput(errorMessage)))
                }
                return
            }

            let (unspentTxOuts, ledgerBlockCount) = account.readSync {
                    ($0.unspentTxOuts(tokenId: amount.tokenId), $0.knowableBlockCount)
            }
            logger.info(
                "Preparing transaction with provided fee... recipient: \(redacting: recipient), " +
                    "amount: \(redacting: amount), fee: \(redacting: fee), unspentTxOutValues: " +
                    "\(redacting: unspentTxOuts.map { $0.value })",
                logFunction: false)
            switch txOutSelector
                .selectTransactionInputs(amount: amount, fee: fee, fromTxOuts: unspentTxOuts)
                .mapError({ error -> TransactionPreparationError in
                    switch error {
                    case .insufficientTxOuts:
                        return .insufficientBalance()
                    case .defragmentationRequired:
                        return .defragmentationRequired()
                    }
                })
            {
            case .success(let txOutsToSpend):
                metaFetcher.blockVersion {
                    switch $0 {
                    case .success(let blockVersion):
                        logger.info(
                            "Transaction prepared with fee. txOutsToSpend: " +
                                """
                                    0x\(redacting: txOutsToSpend.map {
                                        $0.publicKey.hexEncodedString()
                                    })
                                """,
                            logFunction: false)
                        let tombstoneBlockIndex = ledgerBlockCount + 50
                        transactionPreparer.prepareTransaction(
                            inputs: txOutsToSpend,
                            recipient: recipient,
                            memoType: memoType,
                            amount: amount,
                            fee: Amount(fee, in: amount.tokenId),
                            tombstoneBlockIndex: tombstoneBlockIndex,
                            blockVersion: blockVersion,
                            completion: completion)
                    case .failure(let error):
                        logger.info(
                            "prepareTransactionWithFee failure: \(error)",
                            logFunction: false)

                        serialQueue.async {
                            completion(.failure(.connectionError(error)))
                        }
                    }
                }

            case .failure(let error):
                logger.info("prepareTransactionWithFee failure: \(error)", logFunction: false)
                serialQueue.async {
                    completion(.failure(error))
                }
            }
        }

        func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType,
            amount: Amount,
            feeLevel: FeeLevel,
            completion: @escaping (
                Result<PendingSinglePayloadTransaction, TransactionPreparationError>
            ) -> Void
        ) {
            guard amount.value > 0 else {
                let errorMessage = "prepareTransactionWithFeeLevel failure: " +
                    "Cannot spend 0 \(amount.tokenId)"
                logger.error(errorMessage, logFunction: false)
                serialQueue.async {
                    completion(.failure(.invalidInput(errorMessage)))
                }
                return
            }

            metaFetcher.feeStrategy(for: feeLevel, tokenId: amount.tokenId) {
                switch $0 {
                case .success(let feeStrategy):
                    let (unspentTxOuts, ledgerBlockCount) =
                        self.account.readSync {
                            ($0.unspentTxOuts(tokenId: amount.tokenId), $0.knowableBlockCount)
                        }
                    logger.info(
                        "Preparing transaction with fee level... recipient: " +
                            "\(redacting: recipient), amount: \(redacting: amount), feeLevel: " +
                            "\(feeLevel), unspentTxOutValues: " +
                            "\(redacting: unspentTxOuts.map { $0.value })",
                        logFunction: false)
                    switch self.txOutSelector
                        .selectTransactionInputs(
                            amount: amount,
                            feeStrategy: feeStrategy,
                            fromTxOuts: unspentTxOuts)
                        .mapError({ error -> TransactionPreparationError in
                            switch error {
                            case .insufficientTxOuts:
                                return .insufficientBalance()
                            case .defragmentationRequired:
                                return .defragmentationRequired()
                            }
                        })
                    {
                    case .success(let (inputs: inputs, fee: fee)):
                        metaFetcher.blockVersion {
                            switch $0 {
                            case .success(let blockVersion):
                                logger.info(
                                    "Transaction prepared with fee level. fee: \(redacting: fee)",
                                    logFunction: false)
                                let tombstoneBlockIndex = ledgerBlockCount + 50
                                self.transactionPreparer.prepareTransaction(
                                    inputs: inputs,
                                    recipient: recipient,
                                    memoType: memoType,
                                    amount: amount,
                                    fee: Amount(fee, in: amount.tokenId),
                                    tombstoneBlockIndex: tombstoneBlockIndex,
                                    blockVersion: blockVersion,
                                    completion: completion)
                            case .failure(let error):
                                logger.info(
                                    "prepareTransactionWithFee failure: \(error)",
                                    logFunction: false)

                                serialQueue.async {
                                    completion(.failure(.connectionError(error)))
                                }
                            }
                        }
                    case .failure(let error):
                        logger.info(
                            "prepareTransactionWithFeeLevel failure: \(error)",
                            logFunction: false)
                        completion(.failure(error))
                    }
                case .failure(let connectionError):
                    logger.info("failure - error: \(connectionError)")
                    completion(.failure(.connectionError(connectionError)))
                }
            }
        }

        func prepareDefragmentationStepTransactions(
            toSendAmount amountToSend: Amount,
            recoverableMemo: Bool,
            feeLevel: FeeLevel,
            completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
        ) {
            guard amountToSend.value > 0 else {
                let errorMessage =
                    "prepareDefragmentationStepTransactions failure: " +
                    "Cannot spend 0 \(amountToSend.tokenId)"
                logger.error(errorMessage, logFunction: false)
                serialQueue.async {
                    completion(.failure(.invalidInput(errorMessage)))
                }
                return
            }

            metaFetcher.feeStrategy(for: feeLevel, tokenId: amountToSend.tokenId) {
                switch $0 {
                case .success(let feeStrategy):
                    let (unspentTxOuts, ledgerBlockCount) =
                        self.account.readSync {
                            ($0.unspentTxOuts(tokenId: amountToSend.tokenId), $0.knowableBlockCount)
                        }
                    logger.info(
                        "Preparing defragmentation step transactions... amountToSend: " +
                            "\(redacting: amountToSend), feeLevel: \(feeLevel), " +
                            "unspentTxOutValues: \(redacting: unspentTxOuts.map { $0.value })",
                        logFunction: false)
                    switch self.txOutSelector.selectInputsForDefragTransactions(
                        toSendAmount: amountToSend,
                        feeStrategy: feeStrategy,
                        fromTxOuts: unspentTxOuts)
                    {
                    case .success(let defragTxInputs):
                        metaFetcher.blockVersion {
                            switch $0 {
                            case .success(let blockVersion):
                                if !defragTxInputs.isEmpty {
                                    logger.info(
                                        "Preparing \(defragTxInputs.count) defrag transactions",
                                        logFunction: false)
                                }
                                let tombstoneBlockIndex = ledgerBlockCount + 50
                                defragTxInputs.mapAsync({ defragInputs, callback in
                                    self.transactionPreparer.prepareSelfAddressedTransaction(
                                        inputs: defragInputs.inputs,
                                        recoverableMemo: recoverableMemo,
                                        fee: Amount(defragInputs.fee, in: amountToSend.tokenId),
                                        tombstoneBlockIndex: tombstoneBlockIndex,
                                        blockVersion: blockVersion,
                                        completion: callback)
                                }, serialQueue: self.serialQueue, completion: completion)
                            case .failure(let error):
                                logger.info(
                                    "prepareTransactionWithFee failure: \(error)",
                                    logFunction: false)

                                serialQueue.async {
                                    completion(.failure(.connectionError(error)))
                                }
                            }
                        }
                    case .failure(let error):
                        logger.info(
                            "prepareDefragmentationStepTransactions failure: \(error)",
                            logFunction: false)
                        self.serialQueue.async {
                            completion(.failure(.insufficientBalance()))
                        }
                    }
                case .failure(let connectionError):
                    logger.info("failure - error: \(connectionError)")
                    completion(.failure(.connectionError(connectionError)))
                }
            }
        }

        func preparePresignedInputTransaction(
            presignedInput: SignedContingentInput,
            memoType: MemoType,
            fee: Amount,
            completion: @escaping (Result<PendingTransaction, TransactionPreparationError>)
            -> Void
        ) {
            let amountToSend = presignedInput.requiredAmount
            let amountToReceive = presignedInput.rewardAmount

            let (unspentTxOuts, ledgerBlockCount) =
                self.account.readSync {
                    ($0.unspentTxOuts(tokenId: amountToSend.tokenId),
                     $0.knowableBlockCount)
                }

            guard ledgerBlockCount <= presignedInput.tombstoneBlockIndex else {
                serialQueue.async {
                    completion(.failure(.invalidInput("Presigned Input Expired.")))
                }
                return
            }

            guard amountToReceive.tokenId == fee.tokenId else {
                serialQueue.async {
                    completion(.failure(.invalidInput(
                        "Fee token ID must match presigned input's amount to receive token ID.")))
                }
                return
            }

            guard amountToReceive.value >= fee.value else {
                serialQueue.async {
                    completion(.failure(.invalidInput("Reward Amount < Fee.")))
                }
                return
            }

            logger.info(
                "Preparing pre-signed input transaction with fee: " +
                    "\(fee), unspentTxOutValues: " +
                    "\(redacting: unspentTxOuts.map { $0.value })",
                logFunction: false)

            switch self.txOutSelector
                .selectTransactionInput(
                    amount: amountToSend,
                    feeStrategy: FixedFeeStrategy(fee: 0), // zero fee for SCI calculation
                    fromTxOuts: unspentTxOuts)
                .mapError({ error -> TransactionPreparationError in
                    switch error {
                    case .insufficientTxOuts:
                        return .insufficientBalance()
                    case .defragmentationRequired:
                        return .defragmentationRequired()
                    }
                })
            {
            case .success(let (inputs: inputs, fee: _ )):
                metaFetcher.blockVersion {
                    switch $0 {
                    case .success(let blockVersion):
                        logger.info(
                            "Transaction with presigned input prepared with fee:" +
                                "fee: \(redacting: fee)",
                            logFunction: false)

                        let tombstoneBlockIndex =
                            min(ledgerBlockCount + 50, presignedInput.tombstoneBlockIndex)

                        self.transactionPreparer.preparePresignedInputTransaction(
                            presignedInput: presignedInput,
                            inputs: inputs,
                            memoType: memoType,
                            amount: amountToSend,
                            fee: fee,
                            tombstoneBlockIndex: tombstoneBlockIndex,
                            blockVersion: blockVersion,
                            completion: completion)
                    case .failure(let error):
                        logger.info(
                            "preparePresignedInputTransaction failure: \(error)",
                            logFunction: false)

                        serialQueue.async {
                            completion(.failure(.connectionError(error)))
                        }
                    }
                }
            case .failure(let error):
                logger.info(
                    "preparePresignedInputTransaction failure: \(error)",
                    logFunction: false)
                serialQueue.async {
                    completion(.failure(error))
                }
            }
        }

        func preparePresignedInputTransaction(
            presignedInput: SignedContingentInput,
            memoType: MemoType,
            feeLevel: FeeLevel,
            completion: @escaping (Result<PendingTransaction, TransactionPreparationError>)
            -> Void
        ) {
            let amountToSend = presignedInput.requiredAmount
            let amountToReceive = presignedInput.rewardAmount
            let feeTokenId = amountToReceive.tokenId

            metaFetcher.feeStrategy(for: feeLevel, tokenId: feeTokenId) {
                switch $0 {
                case .success(let feeStrategy):

                    let (unspentTxOuts, ledgerBlockCount) =
                        self.account.readSync {
                            ($0.unspentTxOuts(tokenId: amountToSend.tokenId),
                             $0.knowableBlockCount)
                        }

                    if ledgerBlockCount > presignedInput.tombstoneBlockIndex {
                        serialQueue.async {
                            completion(.failure(.invalidInput("Presigned Input Expired.")))
                        }
                        return
                    }

                    // calculate fee
                    //  1 input from SCI creator
                    //  1 input from SCI consumer
                    //  1 output to consumer for reward amount from SCI creator's TxIn
                    //  1 output (change) to return reward overage from creator's TxIn
                    //  1 output to creator for required amount from SCI consumer's TxIn
                    //  1 output (change) to consumer for overage from consumer's TxIn
                    let fee = feeStrategy.fee(numInputs: 2, numOutputs: 4)
                    if amountToReceive.value < fee {
                        serialQueue.async {
                            completion(.failure(.invalidInput("Reward Amount < Fee.")))
                        }
                        return
                    }

                    logger.info(
                        "Preparing pre-signed input transaction with fee level...feeLevel: " +
                            "\(feeLevel), unspentTxOutValues: " +
                            "\(redacting: unspentTxOuts.map { $0.value })",
                        logFunction: false)

                    switch self.txOutSelector
                        .selectTransactionInput(
                            amount: amountToSend,
                            feeStrategy: FixedFeeStrategy(fee: 0), // zero fee for SCI calculation
                            fromTxOuts: unspentTxOuts)
                        .mapError({ error -> TransactionPreparationError in
                            switch error {
                            case .insufficientTxOuts:
                                return .insufficientBalance()
                            case .defragmentationRequired:
                                return .defragmentationRequired()
                            }
                        })
                    {
                    case .success(let (inputs: inputs, fee: _ )):
                        metaFetcher.blockVersion {
                            switch $0 {
                            case .success(let blockVersion):
                                logger.info(
                                    "Transaction with presigned input prepared with fee level. " +
                                        "fee: \(redacting: fee)",
                                    logFunction: false)

                                let tombstoneBlockIndex =
                                    min(ledgerBlockCount + 50, presignedInput.tombstoneBlockIndex)

                                self.transactionPreparer.preparePresignedInputTransaction(
                                    presignedInput: presignedInput,
                                    inputs: inputs,
                                    memoType: memoType,
                                    amount: amountToSend,
                                    fee: Amount(fee, in: presignedInput.feeTokenId),
                                    tombstoneBlockIndex: tombstoneBlockIndex,
                                    blockVersion: blockVersion,
                                    completion: completion)
                            case .failure(let error):
                                logger.info(
                                    "preparePresignedInputTransaction failure: \(error)",
                                    logFunction: false)

                                serialQueue.async {
                                    completion(.failure(.connectionError(error)))
                                }
                            }
                        }
                    case .failure(let error):
                        logger.info(
                            "preparePresignedInputTransaction failure: \(error)",
                            logFunction: false)
                        serialQueue.async {
                            completion(.failure(error))
                        }
                    }
                case .failure(let connectionError):
                    logger.info("failure - error: \(connectionError)")
                    completion(.failure(.connectionError(connectionError)))
                }
            }
        }

    }
}
