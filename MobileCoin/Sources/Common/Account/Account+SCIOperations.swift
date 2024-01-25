//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//
// swiftlint:disable closure_body_length function_body_length

import Foundation

extension Account {
    struct SCIOperations {
        private let serialQueue: DispatchQueue
        private let account: ReadWriteDispatchLock<Account>
        private let metaFetcher: BlockchainMetaFetcher
        private let txOutSelector: TxOutSelector
        private let signedContingentInputCreator: SignedContingentInputCreator
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
            self.signedContingentInputCreator = SignedContingentInputCreator(
                accountKey: account.accessWithoutLocking.accountKey,
                fogMerkleProofService: fogMerkleProofService,
                fogResolverManager: fogResolverManager,
                mixinSelectionStrategy: mixinSelectionStrategy,
                rngSeed: rngSeed,
                targetQueue: targetQueue)
            self.transactionPreparer = TransactionPreparer(
                accountKey: account.accessWithoutLocking.accountKey,
                fogMerkleProofService: fogMerkleProofService,
                fogResolverManager: fogResolverManager,
                mixinSelectionStrategy: mixinSelectionStrategy,
                rngSeed: rngSeed,
                targetQueue: targetQueue)

        }

        private func verifyBlockVersion(
            _ blockVersion: BlockVersion,
            _ completion: @escaping (
                Result<SignedContingentInput, SignedContingentInputCreationError>) -> Void
        ) -> Bool {
            // verify block version >= 3
            guard blockVersion >= 3 else {
                serialQueue.async {
                    completion(.failure(.requiresBlockVersion3(
                        "Block version must be > 3 for SCI support")))
                }
                return false
            }
            return true
        }

        private func verifyAmountIsNonZero(
            _ amount: Amount,
            _ actionDescription: String,
            _ completion: @escaping (
                Result<SignedContingentInput, SignedContingentInputCreationError>) -> Void
        ) -> Bool {
            guard amount.value > 0 else {
                let errorMessage = "createSignedContingentInput failure: " +
                    "Cannot \(actionDescription) 0 \(amount.tokenId)"
                logger.error(errorMessage, logFunction: false)
                serialQueue.async {
                    completion(.failure(.invalidInput(errorMessage)))
                }
                return false
            }
            return true
        }

        private func logTxOuts(_ txOuts: [KnownTxOut], _ message: String) {
            logger.info(
                "\(message): " +
                    """
                        0x\(redacting: txOuts.map {
                            $0.publicKey.hexEncodedString()
                        })
                    """,
                logFunction: false)
        }

        func createSignedContingentInput(
            to recipient: PublicAddress,
            memoType: MemoType,
            amountToSend: Amount,
            amountToReceive: Amount,
            completion: @escaping (
                Result<SignedContingentInput, SignedContingentInputCreationError>
            ) -> Void
        ) {
            guard verifyAmountIsNonZero(amountToSend, "send", completion) else {
                return
            }

            guard verifyAmountIsNonZero(amountToReceive, "receive", completion) else {
                return
            }

            // get all unspent txOuts
            let (unspentTxOuts, ledgerBlockCount) =
            account.readSync {
                ($0.unspentTxOuts(tokenId: amountToSend.tokenId), $0.knowableBlockCount)
            }
            logger.info(
                "Creating signed contingent input to recipient: \(redacting: recipient), " +
                    "amountToSend: \(redacting: amountToSend), " +
                    "amountToRecieve: \(redacting: amountToReceive), " +
                    "unspentTxOutValues: \(redacting: unspentTxOuts.map { $0.value })",
                logFunction: false)

            // fee is zero here, because the fee will be covered by the consumer of the SCI
            switch txOutSelector
                .selectTransactionInputs(amount: amountToSend, fee: 0, fromTxOuts: unspentTxOuts)
            {
            case .success(let txOutsToSpend):
                metaFetcher.blockVersion {
                    switch $0 {
                    case .success(let blockVersion):

                        guard verifyBlockVersion(blockVersion, completion) else {
                            return
                        }

                        logTxOuts(txOutsToSpend, "SCI preparation selected txOutsToSpend")

                        signedContingentInputCreator.createSignedContingentInput(
                            inputs: txOutsToSpend,
                            recipient: recipient,
                            memoType: memoType,
                            amountToSend: amountToSend,
                            amountToReceive: amountToReceive,
                            tombstoneBlockIndex: ledgerBlockCount + 50,
                            blockVersion: blockVersion) { result in
                            serialQueue.async {
                                completion(result)
                            }
                        }
                    case .failure(let error):
                        logger.info("Error: \(error)")

                        serialQueue.async {
                            completion(.failure(.connectionError(error)))
                        }
                    }
                }

            case .failure(let error):
                logger.info("Error: \(error)")
                serialQueue.async {
                    completion(.failure(SignedContingentInputCreationError.create(from: error)))
                }
            }
        }

        func prepareCancelSignedContingentInputTransaction(
            signedContingentInput: SignedContingentInput,
            feeLevel: FeeLevel,
            completion: @escaping (
                Result<PendingSinglePayloadTransaction, SignedContingentInputCancelationError>
            ) -> Void
        ) {
            // check sci is valid
            guard signedContingentInput.isValid else {
                serialQueue.async {
                    completion(.failure(SignedContingentInputCancelationError.invalidSCI))
                }
                return
            }

            // get all unspent txOuts
            let (ownedTxOuts, unspentTxOuts, publicAddress) =
            account.readSync {
                ($0.ownedTxOuts,
                 $0.unspentTxOuts(tokenId: signedContingentInput.rewardAmount.tokenId),
                 $0.publicAddress)
            }

            // match the owned [KnownTxOut] w/the SCI's TxIn's ring to get the SCI's real KnownTxOut
            guard let ownedTxOut = signedContingentInput.matchTxInWith(ownedTxOuts) else {
                serialQueue.async {
                    completion(.failure(SignedContingentInputCancelationError.unownedTxOut()))
                }
                return
            }

            guard let txOut = unspentTxOuts.first(where: { $0.publicKey == ownedTxOut.publicKey })
            else {
                serialQueue.async {
                    completion(.failure(SignedContingentInputCancelationError.alreadySpent()))
                }
                return
            }

            // prepare transaction with txout
            metaFetcher.feeStrategy(for: feeLevel, tokenId: txOut.tokenId) {
                switch $0 {
                case .success(let feeStrategy):
                    metaFetcher.blockVersion {
                        switch $0 {
                        case .success(let blockVersion):
                            let fee = feeStrategy.fee(numInputs: 1, numOutputs: 1)
                            logger.info(
                                "Transaction prepared with fee level. fee: \(redacting: fee)",
                                logFunction: false)

                            guard fee <= txOut.amount.value else {
                                serialQueue.async {
                                    completion(.failure(.inputError("fee > tx amount")))
                                }
                                return
                            }

                            let ledgerBlockCount = self.account.readSync { $0.knowableBlockCount }
                            let tombstoneBlockIndex = ledgerBlockCount + 50
                            self.transactionPreparer.prepareTransaction(
                                inputs: [txOut],
                                recipient: publicAddress,
                                memoType: .unused,
                                amount: Amount(txOut.amount.value - fee, in: txOut.amount.tokenId),
                                fee: Amount(fee, in: txOut.amount.tokenId),
                                tombstoneBlockIndex: tombstoneBlockIndex,
                                blockVersion: blockVersion)
                            { result in
                                switch result {
                                case .success(let pendingTransaction):
                                    serialQueue.async {
                                        completion(.success(pendingTransaction))
                                    }
                                case .failure(let error):
                                    serialQueue.async {
                                        completion(.failure(
                                            .transactionPreparationError(error)))
                                    }
                                }
                            }
                        case .failure(let error):
                            logger.info(
                                "prepareTransactionWithFee failure: \(error)",
                                logFunction: false)

                            serialQueue.async {
                                completion(.failure(.connectionError(error)))
                            }
                        }
                    }

                case .failure(let connectionError):
                    logger.info("failure - error: \(connectionError)")
                    completion(.failure(.connectionError(connectionError)))
                }
            }

            // wait for completion of transaction - look for success
        }
    }
}
