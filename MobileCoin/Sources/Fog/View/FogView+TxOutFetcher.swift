//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

extension FogView {
    struct TxOutFetcher {
        private let serialQueue: DispatchQueue
        private let fogView: ReadWriteDispatchLock<FogView>
        private let accountKey: AccountKey
        private let fogViewService: FogViewService
        private let fogQueryScalingStrategy: FogQueryScalingStrategy

        init(
            fogView: ReadWriteDispatchLock<FogView>,
            accountKey: AccountKey,
            fogViewService: FogViewService,
            fogQueryScalingStrategy: FogQueryScalingStrategy,
            targetQueue: DispatchQueue?
        ) {
            logger.info("")
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(FogView.self).\(Self.self)",
                target: targetQueue)
            self.fogView = fogView
            self.accountKey = accountKey
            self.fogViewService = fogViewService
            self.fogQueryScalingStrategy = fogQueryScalingStrategy
        }

        private var allRngTxOutsFoundBlockCount: UInt64 {
            fogView.readSync { $0.allRngTxOutsFoundBlockCount }
        }

        func fetchTxOuts(
            partialResultsWithWriteLock: @escaping ([KnownTxOut]) -> Void,
            completion: @escaping (Result<(), ConnectionError>) -> Void
        ) {
            let queryScaling = fogQueryScalingStrategy.create()

            func performSearchRound(targetBlockCount maybeTargetBlockCount: UInt64?) {
                checkForNewTxOutsLoop(
                    targetBlockCount: maybeTargetBlockCount,
                    numOutputs: queryScaling.next(),
                    partialResultsWithWriteLock: partialResultsWithWriteLock
                ) {
                    logger.info("")
                    guard let highestProcessedBlockCount = $0.successOr(completion: completion)
                    else { return }

                    // After the first call we know the current number of blocks processed by
                    // the fog ingest server, so we'll use that to try to build a complete view
                    // of the ledger for our account up to this number of blocks. We keep using
                    // this `targetBlockCount` because the ledger is always growing and we have
                    // to stop and declare the balance check finished at some point.
                    let targetBlockCount = maybeTargetBlockCount ?? highestProcessedBlockCount

                    if self.allRngTxOutsFoundBlockCount >= targetBlockCount {
                        // Search complete
                        completion(.success(()))
                    } else {
                        // Do another search round
                        performSearchRound(targetBlockCount: targetBlockCount)
                    }
                }
            }
            performSearchRound(targetBlockCount: nil)
        }

        private func checkForNewTxOutsLoop(
            targetBlockCount: UInt64?,
            numOutputs: PositiveInt,
            partialResultsWithWriteLock: @escaping ([KnownTxOut]) -> Void,
            completion: @escaping (Result<UInt64, ConnectionError>) -> Void
        ) {
            logger.info("targetBlockCount: \(String(describing: targetBlockCount)), " +
                "numOutputs: \(numOutputs)")
            var requestAad = FogView_QueryRequestAAD()
            let searchAttempt: FogSearchAttempt = fogView.readSync {
                requestAad.startFromUserEventID = $0.nextStartFromUserEventId

                // Note: converting directly from blockIndex to blockCount here is valid.
                requestAad.startFromBlockIndex = $0.allRngRecordsKnownBlockCount

                return $0.searchAttempt(
                    requestedBlockCount: targetBlockCount,
                    numOutputs: numOutputs,
                    minOutputsPerSelectedRng: min(2, numOutputs.value))
            }
            var request = FogView_QueryRequest()
            request.getTxos = searchAttempt.searchKeys.map { $0.bytes }
            fogViewService.query(requestAad: requestAad, request: request) {
                completion($0.flatMap { response in
                    Self.printFogQueryResponseDebug(response: response)
                    return self.fogView.writeSync { fogView in
                        fogView.processQueryResponse(
                            response,
                            searchAttempt: searchAttempt,
                            accountKey: self.accountKey
                        ).map { newTxOuts in
                            logger.info("processSearchResults: Found " +
                                "\(redacting: newTxOuts.count) new TxOuts")

                            partialResultsWithWriteLock(newTxOuts)

                            return response.highestProcessedBlockCount
                        }
                    }
                })
            }
        }
    }
}

extension FogView.TxOutFetcher {
    private static func printFogQueryResponseDebug(response: FogView_QueryResponse) {
        logger.info("rng record count: \(response.rngs.count)")
        logger.info("TxOutResult count: \(redacting: response.txOutSearchResults.count)")
        let hits = response.txOutSearchResults.filter { $0.resultCodeEnum == .found }
        logger.info("TxOutResult success count: \(redacting: hits.count)")
        logger.info("highestProcessedBlockCount: \(response.highestProcessedBlockCount)")
        logger.info("missedBlockRanges.count: \(response.missedBlockRanges.count)")
        logger.info("lastKnownBlockCount: \(response.lastKnownBlockCount), " +
            "lastKnownBlockCumulativeTxoCount: " +
            "\(response.lastKnownBlockCumulativeTxoCount)")
        logger.info("txOutResults result codes: " +
            "\(redacting: response.txOutSearchResults.map { $0.resultCode })")
    }
}
