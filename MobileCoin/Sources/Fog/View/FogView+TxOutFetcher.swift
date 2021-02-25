//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

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
            completion: @escaping (Result<(), Error>) -> Void
        ) {
            let queryScaling = fogQueryScalingStrategy.create()

            func performSearchRound(targetBlockCount maybeTargetBlockCount: UInt64?) throws {
                try checkForNewTxOutsLoop(
                    targetBlockCount: maybeTargetBlockCount,
                    numOutputs: queryScaling.next(),
                    partialResultsWithWriteLock: partialResultsWithWriteLock
                ) {
                    do {
                        let highestProcessedBlockCount = try $0.get()

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
                            try performSearchRound(targetBlockCount: targetBlockCount)
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            }

            do {
                try performSearchRound(targetBlockCount: nil)
            } catch {
                // We haven't dispatched yet, so make sure we do that
                serialQueue.async {
                    completion(.failure(error))
                }
            }
        }

        private var allRngTxOutsFoundBlockCount: UInt64 {
            fogView.readSync { $0.allRngTxOutsFoundBlockCount }
        }

        private var allRngRecordsKnownBlockCount: UInt64 {
            fogView.readSync { $0.allRngRecordsKnownBlockCount }
        }

        private func checkForNewTxOutsLoop(
            targetBlockCount: UInt64?,
            numOutputs: Int,
            partialResultsWithWriteLock: @escaping
                ((newTxOuts: [KnownTxOut], missedBlocks: [Range<UInt64>])) -> Void,
            completion: @escaping (Result<UInt64, Error>) -> Void
        ) throws {
            let searchAttempt = try fogView.readSync { fogView in
                try fogView.searchAttempt(
                    requestedBlockCount: targetBlockCount,
                    numOutputs: numOutputs,
                    minOutputsPerSelectedRng: min(2, numOutputs))
            }

            var requestAad = FogView_QueryRequestAAD()
            requestAad.startFromBlockIndex = allRngRecordsKnownBlockCount
            var request = FogView_QueryRequest()
            request.getTxos = searchAttempt.searchKeys.map { $0.bytes }
            fogViewService.query(requestAad: requestAad, request: request) {
                completion($0.flatMap { response in
                    self.printFogQueryResponseDebug(response: response)

                    try self.fogView.writeSync { fogView in
                        let newTxOuts = try fogView.processSearchResult(
                            accountKey: self.accountKey,
                            searchAttempt: searchAttempt,
                            response: response)
                        print("processSearchResults: Found \(newTxOuts.count) new TxOuts")
                        let missedBlocks = response.missedBlockRanges.map { $0.range }
                        let partialResults = (newTxOuts: newTxOuts, missedBlocks: missedBlocks)

                        partialResultsWithWriteLock(partialResults)
                    }

                    return response.highestProcessedBlockCount
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
