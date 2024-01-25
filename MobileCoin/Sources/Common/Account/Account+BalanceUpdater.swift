//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable closure_body_length multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension Account {
    struct BalanceUpdater {
        private let serialQueue: DispatchQueue
        private let account: ReadWriteDispatchLock<Account>
        private let txOutFetcher: FogView.TxOutFetcher
        private let viewKeyScanner: FogViewKeyScanner
        private let fogKeyImageChecker: FogKeyImageChecker

        init(
            account: ReadWriteDispatchLock<Account>,
            fogViewService: FogViewService,
            fogKeyImageService: FogKeyImageService,
            fogBlockService: FogBlockService,
            fogQueryScalingStrategy: FogQueryScalingStrategy,
            targetQueue: DispatchQueue?
        ) {
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(Account.self).\(Self.self)",
                target: targetQueue)
            self.account = account
            self.txOutFetcher = FogView.TxOutFetcher(
                fogView: account.mapLockWithoutLocking { $0.fogView },
                accountKey: account.accessWithoutLocking.accountKey,
                fogViewService: fogViewService,
                fogQueryScalingStrategy: fogQueryScalingStrategy,
                targetQueue: targetQueue,
                syncChecker: account.accessWithoutLocking.syncCheckerLock)
            self.viewKeyScanner = FogViewKeyScanner(
                accountKey: account.accessWithoutLocking.accountKey,
                fogBlockService: fogBlockService)
            self.fogKeyImageChecker = FogKeyImageChecker(
                fogKeyImageService: fogKeyImageService,
                targetQueue: targetQueue,
                syncChecker: account.accessWithoutLocking.syncCheckerLock)
        }

        func updateBalances(completion: @escaping (Result<Balances, BalanceUpdateError>) -> Void) {
            logger.info("Updating balance...", logFunction: false)
            checkForNewTxOuts {
                guard $0.mapError({
                    .connectionError($0)
                }).successOr(completion: completion) != nil else {
                    logger.warning(
                        "Failed to update balance: checkForNewTxOuts error: \($0)",
                        logFunction: false)
                    return
                }

                self.checkForSpentTxOuts {
                    guard $0.mapError({
                        .connectionError($0)
                    }).successOr(completion: completion) != nil else {
                        logger.warning(
                            "Failed to update balance: checkForSpentTxOuts error: \($0)",
                            logFunction: false)
                        return
                    }

                    let fogInSync = account.accessWithoutLocking.syncCheckerLock.readSync({
                        $0.inSync()
                    })
                    guard fogInSync.mapError({
                        .fogSyncError($0)
                    }).successOr(completion: completion) != nil else {
                        logger.warning(
                            "Failed to update balance: checkForSpentTxOuts error: \(fogInSync)",
                            logFunction: false)
                        return
                    }

                    let balances = self.account.readSync { account in
                        account.cachedBalances
                    }

                    logger.info(
                        "Balance updates successful. balances: \(redacting: balances)",
                        logFunction: false)
                    completion(.success(balances))
                }
            }
        }

        func checkForNewTxOuts(completion: @escaping (Result<(), ConnectionError>) -> Void) {
            checkForNewFogViewTxOuts {
                guard $0.successOr(completion: completion) != nil else { return }

                self.viewKeyScanUnscannedMissedBlocks(completion: completion)
            }
        }

        func checkForNewFogViewTxOuts(completion: @escaping (Result<(), ConnectionError>) -> Void) {
            txOutFetcher.fetchTxOuts(partialResultsWithWriteLock: { newTxOuts in
                logger.info(
                    "Found \(redacting: newTxOuts.count) new TxOuts using Fog View",
                    logFunction: false)
                let account = self.account.accessWithoutLocking
                account.addTxOuts(newTxOuts)
            }, completion: completion)
        }

        func viewKeyScanUnscannedMissedBlocks(
            completion: @escaping (Result<(), ConnectionError>) -> Void
        ) {
            let unscannedBlockRanges = account.readSync { $0.unscannedMissedBlocksRanges }
            guard !unscannedBlockRanges.isEmpty else {
                logger.debug("0 unscanned missed blocks, skipping.", logFunction: false)
                serialQueue.async {
                    completion(.success(()))
                }
                return
            }
            viewKeyScanner.viewKeyScanBlocks(blockRanges: unscannedBlockRanges) {
                completion($0.map { foundTxOuts in
                    self.account.writeSync {
                        $0.addViewKeyScanResults(
                            scannedBlockRanges: unscannedBlockRanges,
                            foundTxOuts: foundTxOuts)
                    }
                })
            }
        }

        func checkForSpentTxOuts(completion: @escaping (Result<(), ConnectionError>) -> Void) {
            let keyImageTrackers = account.mapLock { account in
                account.allTxOutTrackers.filter { !$0.isSpent }.map { $0.keyImageTracker }
            }
            let queries = keyImageTrackers.readSync {
                $0.map { ($0.keyImage, $0.nextKeyImageQueryBlockIndex) }
            }
            fogKeyImageChecker.checkKeyImages(keyImageQueries: queries) {
                completion($0.map { statuses in
                    keyImageTrackers.writeSync { keyImageTrackers in
                        for (tracker, status) in zip(keyImageTrackers, statuses) {
                            tracker.spentStatus = status
                        }
                    }
                })
            }
        }
    }
}
