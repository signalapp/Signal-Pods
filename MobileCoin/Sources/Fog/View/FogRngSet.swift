//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

final class FogRngSet {
    private var ingestInvocationIdToRngTrackers: [Int64: RngTracker] = [:]
    private(set) var rngRecordsKnownBlockCount: UInt64 = 0

    var earliestRngRecordStartBlockIndex: UInt64? {
        ingestInvocationIdToRngTrackers.values.map { $0.startBlockIndex }.min()
    }

    var knownBlockCount: UInt64 {
        ingestInvocationIdToRngTrackers.values.map { $0.knownBlockCount }
            .reduce(rngRecordsKnownBlockCount, min)
    }

    func searchAttempt(
        requestedBlockCount: UInt64?,
        numOutputs: PositiveInt,
        minOutputsPerSelectedRng: Int
    ) -> FogSearchAttempt {
        // Max rngs we can select while maintaining the requested minimum outputs per selected rng.
        let maxRngs = 0 < minOutputsPerSelectedRng && minOutputsPerSelectedRng <= numOutputs.value
            ? numOutputs.value / minOutputsPerSelectedRng : numOutputs.value

        let selectedRngs =
            selectRngsForSearch(requestedBlockCount: requestedBlockCount, maxRngs: maxRngs)
        guard !selectedRngs.isEmpty else { return FogSearchAttempt() }

        // Num of outputs to generate per selected rng.
        let outputsPerRng = numOutputs.value / selectedRngs.count
        let numRemainderOutputs = numOutputs.value % selectedRngs.count

        let ingestInvocationIdAndRngSearchAttempt =
            selectedRngs.enumerated().map { i, rngPair -> (Int64, FogRngSearchAttempt) in
                let (ingestInvocationId, rngTracker) = rngPair
                let numOutputs = outputsPerRng + (i < numRemainderOutputs ? 1 : 0)
                let rngSearchAttempt = rngTracker.searchAttempt(numOutputs: numOutputs)
                return (ingestInvocationId, rngSearchAttempt)
            }
        return FogSearchAttempt(
            ingestInvocationIdToRngSearchAttempt: Dictionary(
                uniqueKeysWithValues: ingestInvocationIdAndRngSearchAttempt))
    }

    private func selectRngsForSearch(requestedBlockCount: UInt64?, maxRngs: Int)
        -> [Int64: RngTracker]
    {
        // Filter for rngs that are still active.
        var eligibleRngTrackers = ingestInvocationIdToRngTrackers.filter { $0.value.active }

        if let requestedBlockCount = requestedBlockCount {
            // Filter for rngs that haven't already successfully processed the requested number of
            // blocks.
            //
            // This is how we handle TxOut search pagination. If we repeatedly perform search
            // attempts with the same `requestedBlockCount` (e.g. when performing a single balance
            // check), eventually all rngs will have a `knownBlockCount` of at least
            // `requestedBlockCount`.
            eligibleRngTrackers = eligibleRngTrackers.filter {
                $0.value.knownBlockCount < requestedBlockCount
            }
        }

        return Dictionary(uniqueKeysWithValues: Array(eligibleRngTrackers.prefix(maxRngs)))
    }

    func processQueryResponse(
        searchAttempt: FogSearchAttempt,
        queryResponse: FogView_QueryResponse,
        accountKey: AccountKey
    ) -> Result<[FogView_TxOutSearchResult], ConnectionError> {
        processRngRecords(
            accountKey: accountKey,
            rngRecords: queryResponse.rngs,
            highestProcessedBlockCount: queryResponse.highestProcessedBlockCount
        ).flatMap {
            processDecommissionedRngs(
                decommissionedRngs: queryResponse.decommissionedIngestInvocations)
            return processTxOutResults(
                searchAttempt: searchAttempt,
                txOutResults: queryResponse.txOutSearchResults,
                highestProcessedBlockCount: queryResponse.highestProcessedBlockCount)
        }
    }

    private func processRngRecords(
        accountKey: AccountKey,
        rngRecords: [FogView_RngRecord],
        highestProcessedBlockCount: UInt64
    ) -> Result<(), ConnectionError> {
        for rngRecord in rngRecords
            where ingestInvocationIdToRngTrackers[rngRecord.ingestInvocationID] == nil
        {
            switch RngTracker.make(rngRecord: rngRecord, accountKey: accountKey) {
            case .success(let rngTracker):
                ingestInvocationIdToRngTrackers[rngRecord.ingestInvocationID] = rngTracker
            case .failure(let error):
                return .failure(error)
            }
        }

        if highestProcessedBlockCount > rngRecordsKnownBlockCount {
            rngRecordsKnownBlockCount = highestProcessedBlockCount
        }

        return .success(())
    }

    private func processDecommissionedRngs(
        decommissionedRngs: [FogView_DecommissionedIngestInvocation]
    ) {
        for decommissionedRng in decommissionedRngs {
            if let rngTracker =
                ingestInvocationIdToRngTrackers[decommissionedRng.ingestInvocationID]
            {
                rngTracker.decommissioned = true
            }
        }
    }

    private func processTxOutResults(
        searchAttempt: FogSearchAttempt,
        txOutResults: [FogView_TxOutSearchResult],
        highestProcessedBlockCount: UInt64
    ) -> Result<[FogView_TxOutSearchResult], ConnectionError> {
        let searchKeyToTxOutResult = Dictionary(
            txOutResults.map { ($0.searchKey, $0) },
            uniquingKeysWith: { key1, _ in key1 })

        return searchAttempt.ingestInvocationIdToRngSearchAttempt
            .map { ingestInvocationId, rngSearchAttempt
                    -> Result<[FogView_TxOutSearchResult], ConnectionError> in
                guard let rngTracker = ingestInvocationIdToRngTrackers[ingestInvocationId] else {
                    // This condition is considered a programming error and mean `searchAttempt` was
                    // created using a different `FogRngSet` instance. We silently fail here, since
                    // we know we're in a good state anyway.
                    assertionFailure("Error: \(Self.self).\(#function): RngTracker not found for " +
                        "rngKey in search attempt. ingestInvocationId: \(ingestInvocationId)")
                    return .success([])
                }

                // Filter for only the outputs we searched for.
                let rngSearchKeyToTxOutResult: [Data: FogView_TxOutSearchResult] = Dictionary(
                    rngSearchAttempt.searchKeys.map { $0.bytes }.compactMap {
                        if let txOutResult = searchKeyToTxOutResult[$0] {
                            return ($0, txOutResult)
                        }
                        return nil
                    },
                    uniquingKeysWith: { key1, _ in key1 })

                return rngTracker.processSearchKeyResults(
                    rngSearchKeyToTxOutResult: rngSearchKeyToTxOutResult,
                    highestProcessedBlockCount: highestProcessedBlockCount)
            }.collectResult().map {
                $0.flatMap { $0 }
            }
    }
}

private final class RngTracker {
    let rng: FogRng
    let startBlockIndex: UInt64

    /// Whether this RNG is still in use by Fog.
    ///
    /// If an RNG has been decommissioned, then all `TxOut`'s corresponding to the RNG are available
    /// for immediate retrieval from Fog. This means that once we encounter a search miss we can
    /// stop considering the RNG when generating search keys for a `TxOut` search.
    var decommissioned: Bool = false

    /// Whether we have found all `TxOut`'s for this RNG.
    ///
    /// An RNG is active until the RNG has been both decommissioned and we've encountered at least
    /// one search miss since.
    var active: Bool = true

    /// Number of blocks for which all `TxOut`s for this RNG are known.
    ///
    /// Represents the number of blocks for which we can guarantee that all `TxOut`'s corresponding
    /// to this RNG have been found. Put another way, we can guarantee that the next output from
    /// this RNG has no corresponding `TxOut` within this block range.
    ///
    /// This starts at either `0` or the RNG's `startBlock`. Each time we do a search, if we
    /// encounter at least one miss (a.k.a. a `TxOut` is not found for an output from this RNG),
    /// then we set this value to the `highestProcessedBlockCount` returned in the search response.
    var knownBlockCount: UInt64

    init(rng: FogRng, startBlockIndex: UInt64) {
        self.rng = rng
        self.startBlockIndex = startBlockIndex
        // We assign a blockCount with the value of a blockIndex because, if X is the block index of
        // the first block that the rng is active, then X is also the number of blocks that came
        // before that block, hence our knownBlockCount. E.g. if the startBlockIndex is 1, 1 is also
        // the number of blocks before block index 1.
        self.knownBlockCount = startBlockIndex
    }

    func searchAttempt(numOutputs: Int) -> FogRngSearchAttempt {
        let outputs = rng.outputs(count: numOutputs)
        let searchKeys = outputs.map { FogSearchKey($0) }
        return FogRngSearchAttempt(searchKeys: searchKeys)
    }

    func processSearchKeyResults(
        rngSearchKeyToTxOutResult: [Data: FogView_TxOutSearchResult],
        highestProcessedBlockCount: UInt64
    ) -> Result<[FogView_TxOutSearchResult], ConnectionError> {
        var foundTxOutResults: [FogView_TxOutSearchResult] = []

        searchResultLoop: while true {
            let output = rng.output

            guard let txOutResult = rngSearchKeyToTxOutResult[output] else {
                // Either we've found all the outputs we searched for or we've processed txos since
                // this search attempt was made. Either way, if the next output we need wasn't one
                // of the ones searched for or wasn't in the search results, then there's nothing
                // else we can do with this rng.
                break
            }

            switch txOutResult.resultCodeEnum {
            case .found:
                foundTxOutResults.append(txOutResult)
                rng.advance()
            case .notFound:
                // The search key failed to return a `TxOut` during this search attempt.

                if highestProcessedBlockCount > knownBlockCount {
                    // `highestProcessedBlockCount` is the number of blocks that fog guarantees it
                    // finished processing when performing the search, so we store
                    // `highestProcessedBlockCount` as the `knownBlockCount` for this RNG on the
                    // assumption that if we encountered a miss for this RNG, then there are no more
                    // `TxOut`'s that can be found for this RNG in the first
                    // `highestProcessedBlockCount` number of blocks in the ledger.
                    knownBlockCount = highestProcessedBlockCount
                }

                // Break on the first miss
                break searchResultLoop
            case .rateLimited:
                return .failure(.serverRateLimited("Fog View return error code: RateLimited."))
            case .badSearchKey, .internalError, .intentionallyUnused, .UNRECOGNIZED:
                return .failure(.invalidServerResponse(
                    "Fog View result error: \(txOutResult.resultCodeEnum), response: " +
                    "\(txOutResult)"))
            }
        }

        return .success(foundTxOutResults)
    }
}

extension RngTracker {
    static func make(rngRecord: FogView_RngRecord, accountKey: AccountKey)
        -> Result<RngTracker, ConnectionError>
    {
        switch FogRng.make(accountKey: accountKey, fogRngKey: FogRngKey(rngRecord.pubkey)) {
        case .success(let rng):
            return .success(RngTracker(rng: rng, startBlockIndex: rngRecord.startBlock))
        case .failure(.invalidKey):
            return .failure(.invalidServerResponse("Fog view returned invalid kex rng key."))
        case .failure(.unsupportedCryptoBoxVersion):
            return .failure(.outdatedClient("Fog view returned unsupported kex rng version."))
        }
    }

    convenience init(rng: FogRng, rngRecord: FogView_RngRecord) {
        self.init(rng: rng, startBlockIndex: rngRecord.startBlock)
    }
}

struct FogSearchAttempt {
    fileprivate let ingestInvocationIdToRngSearchAttempt: [Int64: FogRngSearchAttempt]

    fileprivate init(ingestInvocationIdToRngSearchAttempt: [Int64: FogRngSearchAttempt]? = nil) {
        self.ingestInvocationIdToRngSearchAttempt = ingestInvocationIdToRngSearchAttempt ?? [:]
    }

    var searchKeys: [FogSearchKey] {
        ingestInvocationIdToRngSearchAttempt.values.flatMap { $0.searchKeys }
    }
}

private struct FogRngSearchAttempt {
    let searchKeys: [FogSearchKey]
}
