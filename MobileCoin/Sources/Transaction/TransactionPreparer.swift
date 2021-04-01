//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count multiline_function_chains

import Foundation

struct TransactionPreparer {
    private let serialQueue: DispatchQueue
    private let accountKey: AccountKey
    private let selfPaymentAddress: PublicAddress
    private let fogResolverManager: FogResolverManager
    private let mixinSelectionStrategy: MixinSelectionStrategy
    private let fogMerkleProofFetcher: FogMerkleProofFetcher

    init(
        accountKey: AccountKey,
        fogMerkleProofService: FogMerkleProofService,
        fogResolverManager: FogResolverManager,
        mixinSelectionStrategy: MixinSelectionStrategy,
        targetQueue: DispatchQueue?
    ) {
        logger.info("")
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
    }

    func prepareSelfAddressedTransaction(
        inputs: [KnownTxOut],
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        completion: @escaping (
            Result<Transaction, DefragTransactionPreparationError>
        ) -> Void
    ) {
        logger.info("")
        guard UInt64.safeCompare(
                sumOfValues: inputs.map { $0.value },
                isGreaterThanValue: fee)
        else {
            logger.warning("failure - sumOfValues inputs: \(redacting: inputs) " +
                            "isGreaterThanValue fee: \(redacting: fee)")
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
                        inputs: preparedInputs,
                        accountKey: self.accountKey,
                        sendingAllTo: self.selfPaymentAddress,
                        fee: fee,
                        tombstoneBlockIndex: tombstoneBlockIndex,
                        fogResolver: fogResolver
                    ).mapError { .invalidInput(String(describing: $0)) }
                    .map { $0.transaction }
                })
        })
    }

    func prepareTransaction(
        inputs: [KnownTxOut],
        recipient: PublicAddress,
        amount: UInt64,
        fee: UInt64,
        tombstoneBlockIndex: UInt64,
        completion: @escaping (
            Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
        ) -> Void
    ) {
        logger.info("")
        guard amount > 0, let amount = PositiveUInt64(amount) else {
            logger.warning("cannot spend 0 MOB")
            serialQueue.async {
                completion(.failure(.invalidInput("Cannot spend 0 MOB")))
            }
            return
        }
        guard UInt64.safeCompare(
                sumOfValues: inputs.map { $0.value },
                isGreaterThanSumOfValues: [amount.value, fee])
        else {
            logger.warning("sum of inputs is greater than amount + fee")
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
                        inputs: preparedInputs,
                        accountKey: self.accountKey,
                        to: recipient,
                        amount: amount,
                        changeAddress: self.selfPaymentAddress,
                        fee: fee,
                        tombstoneBlockIndex: tombstoneBlockIndex,
                        fogResolver: fogResolver
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
        logger.info("")
        let inputsMixinIndices = mixinSelectionStrategy.selectMixinIndices(
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
            self.processResults(
                inputs: inputs,
                ledgerTxOutCount: ledgerTxOutCount,
                results: $0,
                completion: completion)
        }
    }

    private func processResults(
        inputs: [KnownTxOut],
        ledgerTxOutCount: UInt64?,
        results: Result<[[(TxOut, TxOutMembershipProof)]], FogMerkleProofFetcherError>,
        completion: @escaping (Result<[PreparedTxInput], ConnectionError>) -> Void
    ) {
        logger.info("")
        switch results {
        case .success(let inputsMixinOutputs):
            logger.info("Processing results successful")
            completion(zip(inputs, inputsMixinOutputs).map { knownTxOut, mixinOutputs in
                PreparedTxInput.make(knownTxOut: knownTxOut, ring: mixinOutputs)
                    .mapError { .invalidServerResponse(String(describing: $0)) }
            }.collectResult())
        case .failure(let error):
            switch error {
            case .connectionError(let connectionError):
                logger.warning("failure - connection error")
                completion(.failure(connectionError))
            case let .outOfBounds(blockCount: blockCount, ledgerTxOutCount: responseTxOutCount):
                if let ledgerTxOutCount = ledgerTxOutCount {
                    logger.warning(
                        "Fog GetMerkleProof returned " +
                        "doesNotExist, even though txo indices were limited by " +
                        "globalTxoCount returned by previous call to GetMerkleProof. " +
                        "Previously returned globalTxoCount: \(ledgerTxOutCount)")
                    completion(.failure(.invalidServerResponse(
                        "Fog GetMerkleProof returned " +
                        "doesNotExist, even though txo indices were limited by " +
                        "globalTxoCount returned by previous call to GetMerkleProof. " +
                        "Previously returned globalTxoCount: \(ledgerTxOutCount)")))
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
