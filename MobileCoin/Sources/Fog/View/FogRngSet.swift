//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count

import Foundation
import LibMobileCoin

final class FogRngSet {
    private var ingestInvocationIdToRngTrackers: [Int32: RngTracker] = [:]
    private(set) var rngRecordsKnownBlockCount: UInt64 = 0

    var knownBlockCount: UInt64 {
        ingestInvocationIdToRngTrackers.values.map { $0.knownBlockCount }
            .reduce(rngRecordsKnownBlockCount, min)
    }

    func searchAttempt(
        requestedBlockCount: UInt64?,
        numOutputs: Int,
        minOutputsPerSelectedRng: Int
    ) throws -> FogSearchAttempt {
        guard numOutputs > 0 else {
            throw MalformedInput("\(Self.self).\(#function): attempting to search for 0 outputs")
        }
        guard minOutputsPerSelectedRng <= numOutputs else {
            throw MalformedInput("\(Self.self).\(#function): minOutputsPerSelectedRng " +
                "(\(minOutputsPerSelectedRng)) must be <= numOutputs (\(numOutputs))")
        }

        let selectedRngs = selectRngsForSearch(
            requestedBlockCount: requestedBlockCount,
            numOutputs: numOutputs,
            minOutputsPerSelectedRng: minOutputsPerSelectedRng)
        guard !selectedRngs.isEmpty else { return FogSearchAttempt() }

        // Num of outputs to generate per selected rng
        let outputsPerRng = numOutputs / selectedRngs.count
        let numRemainderOutputs = numOutputs % selectedRngs.count

        let ingestInvocationIdAndRngSearchAttempt =
            selectedRngs.enumerated().map { i, rngPair -> (Int32, FogRngSearchAttempt) in
                let (rngKey, rngTracker) = rngPair
                let numOutputs = outputsPerRng + (i < numRemainderOutputs ? 1 : 0)
                let rngSearchAttempt = rngTracker.searchAttempt(numOutputs: numOutputs)
                return (rngKey, rngSearchAttempt)
            }
        return FogSearchAttempt(
            ingestInvocationIdToRngSearchAttempt: Dictionary(
                uniqueKeysWithValues: ingestInvocationIdAndRngSearchAttempt))
    }

    private func selectRngsForSearch(
        requestedBlockCount: UInt64?,
        numOutputs: Int,
        minOutputsPerSelectedRng: Int
    ) -> [Int32: RngTracker] {
        // Max rngs we can select while maintaining the minimum outputs per selected rng requirement
        let maxRngs = minOutputsPerSelectedRng == 0 ? numOutputs
            : numOutputs / minOutputsPerSelectedRng

        // Filter for rngs that are still active
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

    func processSearchResults(
        searchAttempt: FogSearchAttempt,
        accountKey: AccountKey,
        rngsRecords: [FogView_RngRecord],
        decommissionedRngs: [FogView_DecommissionedIngestInvocation],
        txOutResults: [FogView_TxOutSearchResult],
        blockCount: UInt64
    ) throws -> [FogView_TxOutSearchResult] {
        try processRngRecords(
            accountKey: accountKey,
            rngRecords: rngsRecords,
            blockCount: blockCount)
        processDecommissionedRngs(decommissionedRngs: decommissionedRngs)
        return try processTxOutResults(
            searchAttempt: searchAttempt,
            txOutResults: txOutResults,
            blockCount: blockCount)
    }

    private func processRngRecords(
        accountKey: AccountKey,
        rngRecords: [FogView_RngRecord],
        blockCount: UInt64
    ) throws {
        for rngRecord in rngRecords
            where ingestInvocationIdToRngTrackers[rngRecord.ingestInvocationID] == nil
        {
            let fogRngKey = FogRngKey(rngRecord.pubkey)
            let rng = try FogRng(accountKey: accountKey, fogRngKey: fogRngKey)
            let rngTracker = RngTracker(rng: rng, startBlock: rngRecord.startBlock)
            ingestInvocationIdToRngTrackers[rngRecord.ingestInvocationID] = rngTracker
        }
        rngRecordsKnownBlockCount = blockCount
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
        blockCount: UInt64
    ) throws -> [FogView_TxOutSearchResult] {
        let searchKeyToTxOutResult = Dictionary(
            txOutResults.map { ($0.searchKey, $0) },
            uniquingKeysWith: { key1, _ in key1 })

        return try searchAttempt
            .ingestInvocationIdToRngSearchAttempt
            .flatMap { ingestInvocationId, rngSearchAttempt -> [FogView_TxOutSearchResult] in
                guard let rngTracker = ingestInvocationIdToRngTrackers[ingestInvocationId] else {
                    throw MalformedInput("\(Self.self).\(#function): " +
                        "RngTracker not found for rngKey in search attempt. " +
                        "ingestInvocationId: \(ingestInvocationId)")
                }

                // Filter for only the outputs we searched for
                let rngSearchKeyToTxOutResult: [Data: FogView_TxOutSearchResult] = Dictionary(
                    rngSearchAttempt.searchKeys.map { $0.bytes }.compactMap {
                        if let txOutResult = searchKeyToTxOutResult[$0] {
                            return ($0, txOutResult)
                        }
                        return nil
                    },
                    uniquingKeysWith: { key1, _ in key1 })

                return try rngTracker.processSearchKeyResults(
                    rngSearchKeyToTxOutResult: rngSearchKeyToTxOutResult,
                    blockCount: blockCount)
            }
    }
}

private final class RngTracker {
    let rng: FogRng

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
    /// then we set this value to the `blockCount` returned in the search response.
    var knownBlockCount: UInt64

    init(rng: FogRng, startBlock: UInt64) {
        self.rng = rng
        self.knownBlockCount = startBlock
    }

    func searchAttempt(numOutputs: Int) -> FogRngSearchAttempt {
        let outputs = rng.outputs(count: numOutputs)
        let searchKeys = outputs.map { FogSearchKey($0) }
        return FogRngSearchAttempt(searchKeys: searchKeys)
    }

    func processSearchKeyResults(
        rngSearchKeyToTxOutResult: [Data: FogView_TxOutSearchResult],
        blockCount: UInt64
    ) throws -> [FogView_TxOutSearchResult] {
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

                // `blockCount` is the number of blocks that fog guarantees it finished processing
                // when performing the search, so we store `blockCount` as the `knownBlockCount` for
                // this RNG on the assumption that if we encountered a miss for this RNG, then there
                // are no more `TxOut`'s that can be found for this RNG in the first `blockCount`
                // number of blocks in the ledger.
                knownBlockCount = blockCount

                // Break on the first miss
                break searchResultLoop
            case .badSearchKey, .internalError, .rateLimited, .intentionallyUnused, .UNRECOGNIZED:
                throw ConnectionFailure("Fog View result error: \(txOutResult.resultCodeEnum), " +
                    "response: \(txOutResult)")
            }
        }

        return foundTxOutResults
    }
}

struct FogSearchAttempt {
    fileprivate let ingestInvocationIdToRngSearchAttempt: [Int32: FogRngSearchAttempt]

    fileprivate init(ingestInvocationIdToRngSearchAttempt: [Int32: FogRngSearchAttempt]? = nil) {
        self.ingestInvocationIdToRngSearchAttempt = ingestInvocationIdToRngSearchAttempt ?? [:]
    }

    var searchKeys: [FogSearchKey] {
        ingestInvocationIdToRngSearchAttempt.values.flatMap { $0.searchKeys }
    }
}

private struct FogRngSearchAttempt {
    let searchKeys: [FogSearchKey]
}
