//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable closure_body_length multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif
import os

extension FogView {
    struct TxOutFetcher {
        private let serialQueue: DispatchQueue
        private let fogView: ReadWriteDispatchLock<FogView>
        private let accountKey: AccountKey
        private let fogViewService: FogViewService
        private let fogQueryScalingStrategy: FogQueryScalingStrategy
        private var syncCheckerLock: ReadWriteDispatchLock<FogSyncCheckable>

        init(
            fogView: ReadWriteDispatchLock<FogView>,
            accountKey: AccountKey,
            fogViewService: FogViewService,
            fogQueryScalingStrategy: FogQueryScalingStrategy,
            targetQueue: DispatchQueue?,
            syncChecker: ReadWriteDispatchLock<FogSyncCheckable>
        ) {
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(FogView.self).\(Self.self)",
                target: targetQueue)
            self.fogView = fogView
            self.accountKey = accountKey
            self.fogViewService = fogViewService
            self.fogQueryScalingStrategy = fogQueryScalingStrategy
            self.syncCheckerLock = syncChecker
        }

        private var allRngTxOutsFoundBlockCount: UInt64 {
            fogView.readSync { $0.allRngTxOutsFoundBlockCount }
        }

        func fetchTxOuts(
            partialResultsWithWriteLock: @escaping ([KnownTxOut]) -> Void,
            completion: @escaping (Result<(), ConnectionError>) -> Void
        ) {
            performSearchRound(
                targetBlockCount: nil,
                queryScaling: nil,
                partialResultsWithWriteLock: partialResultsWithWriteLock,
                completion: completion)
        }

        private func performSearchRound(
            targetBlockCount: UInt64?,
            queryScaling: AnyInfiniteIterator<PositiveInt>?,
            partialResultsWithWriteLock: @escaping ([KnownTxOut]) -> Void,
            completion: @escaping (Result<(), ConnectionError>) -> Void
        ) {
            logger.info("Querying Fog View...", logFunction: false)

            let queryScaling = queryScaling ?? fogQueryScalingStrategy.create()
            let numOutputs = queryScaling.next()
            let (requestWrapper, searchAttempt) = fogView.readSync {
                $0.queryRequest(targetBlockCount: targetBlockCount, numOutputs: numOutputs)
            }
            fogViewService.query(requestWrapper: requestWrapper) {
                {
                    guard
                        let highestProcessedBlockCount = try? $0.get().highestProcessedBlockCount
                    else {
                        return
                    }
                    self.syncCheckerLock.writeSync({
                        $0.setViewsHighestKnownBlock(highestProcessedBlockCount)
                    })
                }($0)

                let transform: (FogView_QueryResponse) throws -> UInt64? =
                    { (response: FogView_QueryResponse) throws -> UInt64? in
                        let result = self.fogView.writeSync {
                            $0.processQueryResponse(
                                response,
                                searchAttempt: searchAttempt,
                                accountKey: self.accountKey
                            ).map { processResult -> UInt64? in
                                if !searchAttempt.searchKeys.isEmpty {
                                    partialResultsWithWriteLock(processResult.newTxOuts)
                                }
                                return processResult.nextRoundTargetBlockCount
                            }
                        }
                        return try result.get()
                    }

                let result: Result<UInt64?, ConnectionError> = $0.flatMap(transform)

                switch result {
                case .success(let nextRoundTargetBlockCount):
                    if let nextRoundTargetBlockCount = nextRoundTargetBlockCount {
                        // Reset query scaling if we didn't search for anything last round.
                        let queryScaling = !searchAttempt.searchKeys.isEmpty ? queryScaling : nil

                        // Do another search round
                        self.performSearchRound(
                            targetBlockCount: nextRoundTargetBlockCount,
                            queryScaling: queryScaling,
                            partialResultsWithWriteLock: partialResultsWithWriteLock,
                            completion: completion)
                    } else {
                        // Search complete
                        completion(.success(()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

extension FogView_QueryResponse: CustomRedactingStringConvertible {
    var redactingDescription: String {
        let hits = txOutSearchResults.filter { $0.resultCodeEnum == .found }
        return """
            FogView_QueryResponse:
            rng record count: \(rngs.count)
            TxOutResult count: \(redacting: txOutSearchResults.count)
            TxOutResult success count: \(redacting: hits.count)
            highestProcessedBlockCount: \(highestProcessedBlockCount)
            highestProcessedBlockSignatureTimestamp: \(highestProcessedBlockSignatureTimestamp) \
            \(Date(timeIntervalSince1970: TimeInterval(highestProcessedBlockSignatureTimestamp)))
            decommissionedRngs: \(decommissionedIngestInvocations)
            missedBlockRanges.count: \(missedBlockRanges.count)
            missedBlockRanges: \(missedBlockRanges)
            nextStartFromUserEventId: \(nextStartFromUserEventID)
            lastKnownBlockCount: \(lastKnownBlockCount)
            lastKnownBlockCumulativeTxoCount: \(lastKnownBlockCumulativeTxoCount)
            txOutResults result codes: \(redacting: txOutSearchResults.map { $0.resultCode })
            """
    }
}
