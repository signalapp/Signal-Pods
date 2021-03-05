//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count multiline_function_chains

import Foundation

public enum TransactionPreparationError: Error {
    case invalidInput(String)
    case insufficientBalance
    case connectionError(ConnectionError)
}

extension TransactionPreparationError: CustomStringConvertible {
    public var description: String {
        "Transaction preparation error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: " + reason
            case .insufficientBalance:
                return "Insufficient balance"
            case .connectionError(let innerError):
                return "\(innerError)"
            }
        }()
    }
}

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
            completion: @escaping (
                Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
            ) -> Void
        ) {
            guard amount > 0, let amount = PositiveUInt64(amount) else {
                serialQueue.async {
                    completion(.failure(.invalidInput("Cannot spend 0 MOB")))
                }
                return
            }

            let (balance, unspentTxOuts) = account.readSync { ($0.cachedBalance, $0.unspentTxOuts) }
            let tombstoneBlockIndex = balance.blockCount + 50

            let totalAmount = amount.value + fee
            guard balance.amountPicoMobHigh > 0 || balance.amountPicoMobLow >= totalAmount,
                  let unspentTxOutsWithAmount
                    = SpendableTxOutsWithAmount(unspentTxOuts, totalingAtLeast: totalAmount)
            else {
                serialQueue.async {
                    completion(.failure(.insufficientBalance))
                }
                return
            }

            let txOutsToSpend
                = txOutSelectionStrategy.selectTxOuts(unspentTxOutsWithAmount).txOuts

            doPrepareTransaction(
                to: recipient,
                amount: amount,
                fee: fee,
                tombstoneBlockIndex: tombstoneBlockIndex,
                txOutsToSpend: txOutsToSpend,
                completion: completion)
        }

        private func doPrepareTransaction(
            to recipient: PublicAddress,
            amount: PositiveUInt64,
            fee: UInt64,
            tombstoneBlockIndex: UInt64,
            txOutsToSpend: [KnownTxOut],
            completion: @escaping (
                Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
            ) -> Void
        ) {
            let accountKey = self.accountKey
            let changeAddress = self.publicAddress

            performAsync(body1: { callback in
                fogResolverManager.fogResolver(
                    addresses: [recipient, changeAddress],
                    desiredMinPubkeyExpiry: tombstoneBlockIndex,
                    completion: callback)
            }, body2: { callback in
                prepareInputs(inputs: txOutsToSpend, completion: callback)
            }, completion: {
                completion($0.mapError { .connectionError($0) }
                    .flatMap { fogResolver, preparedInputs in
                        TransactionBuilder.build(
                            inputs: preparedInputs,
                            accountKey: accountKey,
                            to: recipient,
                            amount: amount,
                            changeAddress: changeAddress,
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
            switch results {
            case .success(let inputsMixinOutputs):
                completion(zip(inputs, inputsMixinOutputs).map { knownTxOut, mixinOutputs in
                    PreparedTxInput.make(knownTxOut: knownTxOut, ring: mixinOutputs)
                        .mapError { .invalidServerResponse(String(describing: $0)) }
                }.collectResult())
            case .failure(let error):
                switch error {
                case .connectionError(let connectionError):
                    completion(.failure(connectionError))
                case let .outOfBounds(blockCount: blockCount, ledgerTxOutCount: responseTxOutCount):
                    if let ledgerTxOutCount = ledgerTxOutCount {
                        completion(.failure(.invalidServerResponse(
                            "\(Self.self).\(#function): Fog GetMerkleProof returned " +
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
