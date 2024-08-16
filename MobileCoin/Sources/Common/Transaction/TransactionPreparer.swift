//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count multiline_function_chains function_body_length
// swiftlint:disable array_init

import Foundation

struct TransactionPreparer {
    private let serialQueue: DispatchQueue
    private let accountKey: AccountKey
    private let selfPaymentAddress: PublicAddress
    private let fogResolverManager: FogResolverManager
    private let mixinSelectionStrategy: MixinSelectionStrategy
    private let fogMerkleProofFetcher: FogMerkleProofFetcher
    private let localRng: MobileCoinRng
    private let rngSeed: RngSeed

    init(
        accountKey: AccountKey,
        fogMerkleProofService: FogMerkleProofService,
        fogResolverManager: FogResolverManager,
        mixinSelectionStrategy: MixinSelectionStrategy,
        rngSeed: RngSeed,
        targetQueue: DispatchQueue?
    ) {
        self.serialQueue = DispatchQueue(
            label: "com.mobilecoin.\(Account.self).\(Self.self)",
            target: targetQueue)
        self.accountKey = accountKey
        self.selfPaymentAddress = accountKey.publicAddress
        self.fogResolverManager = fogResolverManager
        self.mixinSelectionStrategy = mixinSelectionStrategy
        self.fogMerkleProofFetcher = FogMerkleProofFetcher(
            fogMerkleProofService: fogMerkleProofService,
            targetQueue: targetQueue)
        self.localRng = MobileCoinDefaultRng()
        self.rngSeed = rngSeed
    }

    func prepareSelfAddressedTransaction(
        inputs: [KnownTxOut],
        recoverableMemo: Bool,
        fee: Amount,
        tombstoneBlockIndex: UInt64,
        blockVersion: BlockVersion,
        completion: @escaping (
            Result<Transaction, DefragTransactionPreparationError>
        ) -> Void
    ) {
        guard UInt64.safeCompare(
                sumOfValues: inputs.map { $0.value },
                isGreaterThanValue: fee.value)
        else {
            logger.warning(
                "Insufficient balance for self-addressed transaction: sum of inputs: " +
                    "\(redacting: inputs.map { $0.value }) <= fee: \(redacting: fee)",
                logFunction: false)
            serialQueue.async {
                completion(.failure(.insufficientBalance()))
            }
            return
        }

        performAsync(body1: { callback in
            fogResolverManager.fogResolver(
                addresses: [selfPaymentAddress],
                desiredMinPubkeyExpiry: tombstoneBlockIndex,
                completion: callback)
        }, body2: { callback in
            prepareInputs(inputs: inputs, completion: callback)
        }, completion: {
            completion($0.mapError { .connectionError($0) }
                .flatMap { fogResolver, preparedInputs in
                    TransactionBuilder.build(
                        context: TransactionBuilder.Context(
                            accountKey: accountKey,
                            blockVersion: blockVersion,
                            fogResolver: fogResolver,
                            memoType: recoverableMemo ? .recoverable : .unused,
                            tombstoneBlockIndex: tombstoneBlockIndex,
                            fee: fee,
                            rngSeed: rngSeed),
                        inputs: preparedInputs,
                        sendingAllTo: self.selfPaymentAddress
                    ).mapError { .invalidInput(String(describing: $0)) }
                    .map { $0.transaction }
                })
        })
    }

    func prepareTransaction(
        inputs: [KnownTxOut],
        recipient: PublicAddress,
        memoType: MemoType,
        amount: Amount,
        fee: Amount,
        tombstoneBlockIndex: UInt64,
        blockVersion: BlockVersion,
        completion: @escaping (
            Result<PendingSinglePayloadTransaction, TransactionPreparationError>
        ) -> Void
    ) {
        guard let tokenId = inputs.first?.amount.tokenId else {
            serialQueue.async {
                completion(.failure(.invalidInput("prepareTransaction error: No inputs available")))
            }
            return
        }
        guard amount.value > 0, let positiveValue = PositiveUInt64(amount.value) else {
            let errorMessage = "PrepareTransactionWithFee error: Cannot spend 0 \(amount.tokenId)"
            logger.error(errorMessage, logFunction: false)
            serialQueue.async {
                completion(.failure(.invalidInput(errorMessage)))
            }
            return
        }
        guard UInt64.safeCompare(
                sumOfValues: inputs.map { $0.value },
                isGreaterThanOrEqualToSumOfValues: [positiveValue.value, fee.value])
        else {
            logger.warning(
                "Insufficient balance to prepare transaction: sum of inputs: " +
                    "\(redacting: inputs.map { $0.value }) < amount: \(redacting: amount) + fee: " +
                    "\(redacting: fee)",
                logFunction: false)
            serialQueue.async {
                completion(.failure(.insufficientBalance()))
            }
            return
        }

        performAsync(body1: { callback in
            fogResolverManager.fogResolver(
                addresses: [recipient, selfPaymentAddress],
                desiredMinPubkeyExpiry: tombstoneBlockIndex,
                completion: callback)
        }, body2: { callback in
            prepareInputs(inputs: inputs, completion: callback)
        }, completion: {
            completion($0.mapError { .connectionError($0) }
                .flatMap { fogResolver, preparedInputs in
                    TransactionBuilder.build(
                        context: TransactionBuilder.Context(
                            accountKey: self.accountKey,
                            blockVersion: blockVersion,
                            fogResolver: fogResolver,
                            memoType: memoType,
                            tombstoneBlockIndex: tombstoneBlockIndex,
                            fee: fee,
                            rngSeed: rngSeed
                            ),
                        inputs: preparedInputs,
                        to: recipient,
                        amount: Amount(positiveValue.value, in: tokenId)
                    ).mapError { .invalidInput(String(describing: $0)) }
                })
        })
    }

    func preparePresignedInputTransaction(
        presignedInput: SignedContingentInput,
        inputs: [KnownTxOut],
        memoType: MemoType,
        amount: Amount,
        fee: Amount,
        tombstoneBlockIndex: UInt64,
        blockVersion: BlockVersion,
        completion: @escaping (
            Result<PendingTransaction, TransactionPreparationError>
        ) -> Void
    ) {
        guard amount.value > 0, let positiveValue = PositiveUInt64(amount.value) else {
            let errorMessage = "preparePresignedInputTransaction error: Cannot spend 0 " +
                "\(amount.tokenId)"
            logger.error(errorMessage, logFunction: false)
            serialQueue.async {
                completion(.failure(.invalidInput(errorMessage)))
            }
            return
        }

        // NOTE: fee is not included here as it will be paid from the SCI reward amount input,
        // not the consumer (this user's) inputs
        guard UInt64.safeCompare(
                sumOfValues: inputs.map { $0.value },
                isGreaterThanOrEqualToSumOfValues: [positiveValue.value])
        else {
            logger.warning(
                "Insufficient balance to prepare transaction: sum of inputs: " +
                    "\(redacting: inputs.map { $0.value }) < amount: \(redacting: amount)",
                logFunction: false)
            serialQueue.async {
                completion(.failure(.insufficientBalance()))
            }
            return
        }

        // create change output for required amount to get SCI input

        performAsync(body1: { callback in
            fogResolverManager.fogResolver(
                addresses: [selfPaymentAddress],
                desiredMinPubkeyExpiry: tombstoneBlockIndex,
                completion: callback)
        }, body2: { callback in
            prepareInputs(inputs: inputs, completion: callback)
        }, completion: {
            completion($0.mapError { .connectionError($0) }
                .flatMap { fogResolver, preparedInputs in

                    TransactionBuilder.build(
                        context: TransactionBuilder.Context(
                            accountKey: self.accountKey,
                            blockVersion: blockVersion,
                            fogResolver: fogResolver,
                            memoType: memoType,
                            tombstoneBlockIndex: tombstoneBlockIndex,
                            fee: fee,
                            rngSeed: rngSeed),
                        inputs: preparedInputs,
                        presignedInput: presignedInput
                    ).mapError { .invalidInput(String(describing: $0)) }
                })
        })
    }

    private func prepareInputs(
        inputs: [KnownTxOut],
        ledgerTxOutCount: UInt64? = nil,
        merkleRootBlock: UInt64? = nil,
        completion: @escaping (Result<[PreparedTxInput], ConnectionError>) -> Void
    ) {
        var inputsMixinIndices: [[UInt64]]

        inputsMixinIndices = mixinSelectionStrategy.selectMixinIndices(
            forRealTxOutIndices: inputs.map { $0.globalIndex },
            selectionRange: ledgerTxOutCount.map { ..<$0 }
        ).map { Array($0) }

        // There's a chance that a txo we selected as a mixin is in a block that's greater than
        // the highest block of our inputs, in which case, using the highest block of our inputs
        // as the requested merkleRootBlock might cause getOutputs to fail. However, the current
        // implementation of the server doesn't use the merkleRootBlock param, so for the time
        // being, we will ignore this concern.
        let merkleRootBlock = merkleRootBlock ?? inputs.map { $0.block.index }.reduce(0, max)

        fogMerkleProofFetcher.getOutputs(
            globalIndicesArray: inputsMixinIndices,
            merkleRootBlock: merkleRootBlock,
            maxNumIndicesPerQuery: 100
        ) {
            self.processFetchResults(
                $0,
                inputs: inputs,
                ledgerTxOutCount: ledgerTxOutCount,
                completion: completion)
        }
    }

    private func processFetchResults(
        _ results: Result<[[(TxOut, TxOutMembershipProof)]], FogMerkleProofFetcherError>,
        inputs: [KnownTxOut],
        ledgerTxOutCount: UInt64?,
        completion: @escaping (Result<[PreparedTxInput], ConnectionError>) -> Void
    ) {
        switch results {
        case .success(let inputsMixinOutputs):
            completion(zip(inputs, inputsMixinOutputs).map { knownTxOut, mixinOutputs in
                PreparedTxInput.make(knownTxOut: knownTxOut, ring: mixinOutputs)
                    .mapError { .invalidServerResponse(String(describing: $0)) }
            }.collectResult())
        case .failure(let error):
            switch error {
            case .connectionError(let connectionError):
                logger.error("FetchMerkleProofs error: \(connectionError)", logFunction: false)
                completion(.failure(connectionError))
            case let .outOfBounds(blockCount: blockCount, ledgerTxOutCount: responseTxOutCount):
                if let ledgerTxOutCount = ledgerTxOutCount {
                    let errorMessage = "Fog GetMerkleProof returned doesNotExist, even though " +
                        "txo indices were limited by globalTxoCount returned by previous call to " +
                        "GetMerkleProof. Previously returned globalTxoCount: " +
                        "\(ledgerTxOutCount), response globalTxoCount: " +
                        "\(responseTxOutCount), response blockCount: \(blockCount)"
                    logger.error(errorMessage, logFunction: false)
                    completion(.failure(.invalidServerResponse(errorMessage)))
                } else {
                    // Re-select mixins, making sure we limit mixin indices to txo count
                    // returned by the server. Uses blockCount returned by server for
                    // merkleRootBlock.
                    prepareInputs(
                        inputs: inputs,
                        ledgerTxOutCount: responseTxOutCount,
                        merkleRootBlock: blockCount,
                        completion: completion)
                }
            }
        }
    }
}
