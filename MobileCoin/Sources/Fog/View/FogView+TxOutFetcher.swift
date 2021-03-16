//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable closure_body_length multiline_function_chains

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
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(FogView.self).\(Self.self)",
                target: targetQueue)
            self.fogView = fogView
            self.accountKey = accountKey
            self.fogViewService = fogViewService
            self.fogQueryScalingStrategy = fogQueryScalingStrategy
        }

        func fetchTxOuts(
            partialResultsWithWriteLock: @escaping
                ((newTxOuts: [KnownTxOut], missedBlocks: [Range<UInt64>])) -> Void,
            completion: @escaping (Result<(), ConnectionError>) -> Void
        ) {
            let queryScaling = fogQueryScalingStrategy.create()

            func performSearchRound(targetBlockCount maybeTargetBlockCount: UInt64?) {
                checkForNewTxOutsLoop(
                    targetBlockCount: maybeTargetBlockCount,
                    numOutputs: queryScaling.next(),
                    partialResultsWithWriteLock: partialResultsWithWriteLock
                ) {
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

        private var allRngTxOutsFoundBlockCount: UInt64 {
            fogView.readSync { $0.allRngTxOutsFoundBlockCount }
        }

        private var allRngRecordsKnownBlockCount: UInt64 {
            fogView.readSync { $0.allRngRecordsKnownBlockCount }
        }

        private func checkForNewTxOutsLoop(
            targetBlockCount: UInt64?,
            numOutputs: PositiveInt,
            partialResultsWithWriteLock: @escaping
                ((newTxOuts: [KnownTxOut], missedBlocks: [Range<UInt64>])) -> Void,
            completion: @escaping (Result<UInt64, ConnectionError>) -> Void
        ) {
            let searchAttempt = fogView.readSync { fogView in
                fogView.searchAttempt(
                    requestedBlockCount: targetBlockCount,
                    numOutputs: numOutputs,
                    minOutputsPerSelectedRng: min(2, numOutputs.value))
            }

            var requestAad = FogView_QueryRequestAAD()
            requestAad.startFromBlockIndex = allRngRecordsKnownBlockCount
            var request = FogView_QueryRequest()
            request.getTxos = searchAttempt.searchKeys.map { $0.bytes }
            fogViewService.query(requestAad: requestAad, request: request) {
                completion($0.flatMap { response in
                    self.printFogQueryResponseDebug(response: response)

                    return self.fogView.writeSync { fogView in
                        fogView.processQueryResponse(
                            searchAttempt: searchAttempt,
                            response: response,
                            accountKey: self.accountKey
                        ).map { newTxOuts in
                            print("processSearchResults: Found \(newTxOuts.count) new TxOuts")
                            var missedBlocks = response.missedBlockRanges.map { $0.range }
                            if let earliestRngStartBlockIndex = fogView.earliestRngStartBlockIndex {
                                missedBlocks = missedBlocks.compactMap { range in
                                    // Check that we don't view key scan missed blocks that occur
                                    // before the first RngRecord's startBlock. This is a workaround
                                    // for Fog Ingest needing to mark the blocks before the first
                                    // run of Fog Ingest as missed blocks.
                                    //
                                    // This can be removed when Fog provides a guarantee that it
                                    // won't report the blocks before Fog Ingest was run for the
                                    // first time as missed.
                                    guard range.lowerBound >= earliestRngStartBlockIndex else {
                                        if range.upperBound <= earliestRngStartBlockIndex {
                                            // Entire missed block range is before the earliest
                                            // RngRecord's startBlock.
                                            return nil
                                        } else {
                                            // Part of missed block range is before the ealiest
                                            // RngRecord's startBlock, so we modify the missed
                                            // blocks range.
                                            return earliestRngStartBlockIndex..<range.upperBound
                                        }
                                    }
                                    return range
                                }
                            }
                            let partialResults = (newTxOuts: newTxOuts, missedBlocks: missedBlocks)

                            partialResultsWithWriteLock(partialResults)

                            return response.highestProcessedBlockCount
                        }
                    }
                })
            }
        }

        private func printFogQueryResponseDebug(response: FogView_QueryResponse) {
            let hits = response.txOutSearchResults.filter { $0.resultCodeEnum == .found }

            print("rng record count: \(response.rngs.count)")
            print("TxOutResult count: \(response.txOutSearchResults.count)")
            print("TxOutResult success count: \(hits.count)")
            print("highestProcessedBlockCount: \(response.highestProcessedBlockCount)")
            print("missedBlockRanges.count: \(response.missedBlockRanges.count)")
            print("lastKnownBlockCount: \(response.lastKnownBlockCount), " +
                "lastKnownBlockCumulativeTxoCount: " +
                "\(response.lastKnownBlockCumulativeTxoCount)")
            print("txOutResults result codes: " +
                "\(response.txOutSearchResults.map { $0.resultCode })")
        }
    }
}
