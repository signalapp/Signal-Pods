//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count multiline_function_chains

import Foundation

extension Account {
    struct TransactionPreparer {
        private let serialQueue: DispatchQueue
        private let account: ReadWriteDispatchLock<Account>
        private let fogResolverManager: FogResolverManager
        private let txOutSelectionStrategy: TxOutSelectionStrategy
        private let mixinSelectionStrategy: MixinSelectionStrategy
        private let fogMerkleProofFetcher: FogMerkleProofFetcher

        init(
            account: ReadWriteDispatchLock<Account>,
            fogMerkleProofService: FogMerkleProofService,
            fogResolverManager: FogResolverManager,
            txOutSelectionStrategy: TxOutSelectionStrategy,
            mixinSelectionStrategy: MixinSelectionStrategy,
            targetQueue: DispatchQueue?
        ) {
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(Account.self).\(Self.self)",
                target: targetQueue)
            self.account = account
            self.fogResolverManager = fogResolverManager
            self.txOutSelectionStrategy = txOutSelectionStrategy
            self.mixinSelectionStrategy = mixinSelectionStrategy
            self.fogMerkleProofFetcher = FogMerkleProofFetcher(
                fogMerkleProofService: fogMerkleProofService,
                targetQueue: targetQueue)
        }

        func prepareTransaction(
            to recipient: PublicAddress,
            amount: UInt64,
            fee: UInt64,
            completion: @escaping (Result<(Transaction, Receipt), Error>) -> Void
        ) {
            let (balance, unspentTxOuts) = account.readSync { ($0.cachedBalance, $0.unspentTxOuts) }
            let tombstoneBlockIndex = balance.blockCount + 50

            do {
                guard amount > 0 else {
                    throw MalformedInput("Cannot spend 0 MOB")
                }

                let totalAmount = amount + fee
                guard balance.amountPicoMobHigh > 0 || balance.amountPicoMobLow >= totalAmount
                else {
                    throw InsufficientBalance(amountRequired: totalAmount, currentBalance: balance)
                }

                let txOutsToSpend = try txOutSelectionStrategy.selectTxOuts(
                    totalingAtLeast: totalAmount,
                    from: unspentTxOuts)

                let inputAmount = txOutsToSpend.map { $0.value }.reduce(0, +)
                guard inputAmount >= totalAmount else {
                    throw InternalError("Input TxOuts total \(inputAmount) does not exceed " +
                        "amount + fee \(amount + fee)")
                }

                doPrepareTransaction(
                    to: recipient,
                    amount: amount,
                    fee: fee,
                    tombstoneBlockIndex: tombstoneBlockIndex,
                    txOutsToSpend: txOutsToSpend,
                    completion: completion)
            } catch {
                serialQueue.async {
                    completion(.failure(error))
                }
            }
        }

        private func doPrepareTransaction(
            to recipient: PublicAddress,
            amount: UInt64,
            fee: UInt64,
            tombstoneBlockIndex: UInt64,
            txOutsToSpend: [KnownTxOut],
            completion: @escaping (Result<(Transaction, Receipt), Error>) -> Void
        ) {
            let accountKey = self.accountKey
            let changeAddress = self.publicAddress

            performAsync(body1: { callback in
                fogResolverManager.fogResolver(
                    addresses: [recipient, changeAddress],
                    desiredMinPubkeyExpiry: tombstoneBlockIndex,
                    completion: callback)
            }, body2: { callback in
                do {
                    try prepareInputs(inputs: txOutsToSpend, completion: callback)
                } catch {
                    serialQueue.async {
                        callback(.failure(error))
                    }
                }
            }, completion: {
                completion($0.flatMap { fogResolver, preparedInputs in
                    try TransactionBuilder.build(
                        inputs: preparedInputs,
                        accountKey: accountKey,
                        to: recipient,
                        amount: amount,
                        changeAddress: changeAddress,
                        fee: fee,
                        tombstoneBlockIndex: tombstoneBlockIndex,
                        fogResolver: fogResolver)
                })
            })
        }

        private func prepareInputs(
            inputs: [KnownTxOut],
            completion: @escaping (Result<[PreparedTxInput], Error>) -> Void
        ) throws {
            try mixinOutputs(inputs: inputs) {
                completion($0.flatMap { inputsMixinOutputs in
                    try zip(inputs, inputsMixinOutputs).map { knownTxOut, mixinOutputs in
                        try PreparedTxInput(knownTxOut: knownTxOut, ring: mixinOutputs)
                    }
                })
            }
        }

        private func mixinOutputs(
            inputs: [KnownTxOut],
            ledgerTxOutCount: UInt64? = nil,
            merkleRootBlock: UInt64? = nil,
            completion: @escaping (Result<[[(TxOut, TxOutMembershipProof)]], Error>) -> Void
        ) throws {
            let inputsMixinIndices = try mixinSelectionStrategy.selectMixinIndices(
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
                do {
                    let fetchResults = try $0.get()

                    try self.processResults(
                        inputs: inputs,
                        ledgerTxOutCount: ledgerTxOutCount,
                        results: fetchResults,
                        completion: completion)
                } catch {
                    completion(.failure(error))
                }
            }
        }

        private func processResults(
            inputs: [KnownTxOut],
            ledgerTxOutCount: UInt64?,
            results: FogMerkleProofFetcher.FetchResult<[[(TxOut, TxOutMembershipProof)]]>,
            completion: @escaping (Result<[[(TxOut, TxOutMembershipProof)]], Error>) -> Void
        ) throws {
            switch results {
            case .success(let inputsMixinOutputs):
                completion(.success(inputsMixinOutputs))
            case let .outOfBounds(blockCount: blockCount, ledgerTxOutCount: responseTxOutCount):
                guard ledgerTxOutCount == nil else {
                    guard let ledgerTxOutCount = ledgerTxOutCount else {
                        fatalError("Unreachable code")
                    }
                    throw ConnectionFailure("\(Self.self).\(#function): " +
                        "Fog GetMerkleProof returned doesNotExist, even though txo indices were " +
                        "limited by globalTxoCount returned by previous call to GetMerkleProof. " +
                        "Previously returned globalTxoCount: \(ledgerTxOutCount)")
                }

                // Re-select mixins, making sure we limit mixin indices to txo count returned by the
                // server. Uses blockCount returned by server for merkleRootBlock.
                try mixinOutputs(
                    inputs: inputs,
                    ledgerTxOutCount: responseTxOutCount,
                    merkleRootBlock: blockCount,
                    completion: completion)
            }
        }

        private var accountKey: AccountKey {
            // Safety: locking is unnecessary because Account.accountKey is immutable.
            account.accessWithoutLocking.accountKey
        }

        private var publicAddress: PublicAddress {
            // Safety: locking is unnecessary because Account.publicAddress is immutable.
            account.accessWithoutLocking.publicAddress
        }
    }
}
