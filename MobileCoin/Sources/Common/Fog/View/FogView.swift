//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogView {
    var syncCheckerLock: ReadWriteDispatchLock<FogSyncCheckable>

    private let rngSet = FogRngSet()
    private(set) var unscannedMissedBlocksRanges: [Range<UInt64>] = []

    /// See `FogUserEvent` in the Fog repo for a list of user events.
    private(set) var nextStartFromUserEventId: Int64 = 0

    var allRngTxOutsFoundBlockCount: UInt64 {
        rngSet.knownBlockCount
    }

    var allRngRecordsKnownBlockCount: UInt64 {
        rngSet.rngRecordsKnownBlockCount
    }

    init(syncChecker: ReadWriteDispatchLock<FogSyncCheckable>) {
        self.syncCheckerLock = syncChecker
    }

    func queryRequest(targetBlockCount: UInt64?, numOutputs: PositiveInt)
        -> (FogViewQueryRequestWrapper, FogSearchAttempt)
    {
        let rngSetSearchAttempt = rngSet.searchAttempt(
            targetBlockCount: targetBlockCount,
            numOutputs: numOutputs,
            minOutputsPerSelectedRng: min(2, numOutputs.value))
        let searchAttempt = FogSearchAttempt(
            rngSetSearchAttempt: rngSetSearchAttempt,
            targetBlockCount: targetBlockCount)

        var wrapper = FogViewQueryRequestWrapper()
        wrapper.requestAad.startFromUserEventID = nextStartFromUserEventId
        wrapper.requestAad.startFromBlockIndex = rngSetSearchAttempt.lowestStartFromBlockIndex
        wrapper.request.getTxos = rngSetSearchAttempt.searchKeys.map { $0.bytes }

        logger.info(
            "Fog view query params: startFromUserEventID: " +
            "\(wrapper.requestAad.startFromUserEventID), startFromBlockIndex: " +
            "\(wrapper.requestAad.startFromBlockIndex)",
            logFunction: false)

        return (wrapper, searchAttempt)
    }

    func processQueryResponse(
        _ queryResponse: FogView_QueryResponse,
        searchAttempt: FogSearchAttempt,
        accountKey: AccountKey
    ) -> Result<(newTxOuts: [KnownTxOut], nextRoundTargetBlockCount: UInt64?), ConnectionError> {
        logger.info("Processing Fog View query response...", logFunction: false)

        syncCheckerLock.writeSync({
           $0.setViewsHighestKnownBlock(queryResponse.highestProcessedBlockCount)
        })

        return rngSet.processRngs(queryResponse: queryResponse, accountKey: accountKey).map {
            processMissedBlockRanges(queryResponse.missedBlockRanges)

            if queryResponse.nextStartFromUserEventID > nextStartFromUserEventId {
                // We set this only after we've processed the info in `QueryResponse` that's
                // considered an event, which currently includes `NewRngRecord`,
                // `DecommissionIngestInvocation`, and `MissingBlocks`. (See `FogUserEvent` in the
                // Fog repo for the canonical list.)
                nextStartFromUserEventId = queryResponse.nextStartFromUserEventID
            }
        }.flatMap {
            rngSet.processTxOutSearchResults(
                queryResponse: queryResponse,
                rngSetSearchAttempt: searchAttempt.rngSetSearchAttempt)
        }.flatMap { searchResults in
            searchResults.map { searchResult in
                Self.decryptSearchResult(searchResult, accountKey: accountKey)
            }.collectResult()
        }.flatMap { txOutRecords in
            txOutRecords.map { txOutRecord in
                LedgerTxOut.make(txOutRecord: txOutRecord, viewKey: accountKey.viewPrivateKey)
            }.collectResult()
        }.map { txOuts in
            let foundTxOuts = Self.ownedTxOuts(validating: txOuts, accountKey: accountKey)

            // After the first call we know the current number of blocks processed by the fog
            // ingest server, so we'll use that to try to build a complete view of the ledger
            // for our account up to this number of blocks. We keep using this
            // `targetBlockCount` because the ledger is always growing and we have to stop and
            // declare the balance check finished at some point.
            let targetBlockCount =
                searchAttempt.targetBlockCount ?? queryResponse.highestProcessedBlockCount

            let performAdditionalSearchRounds = allRngTxOutsFoundBlockCount < targetBlockCount
            let nextRoundTargetBlockCount = performAdditionalSearchRounds ? targetBlockCount : nil

            return (foundTxOuts, nextRoundTargetBlockCount)
        }
    }

    private func processMissedBlockRanges(_ missedBlockRanges: [FogCommon_BlockRange]) {
        var missedBlocks = missedBlockRanges.map { $0.range }
        if let earliestRngStartBlockIndex = rngSet.earliestRngRecordStartBlockIndex {
            missedBlocks = missedBlocks.compactMap { range in
                // Check that we don't view key scan missed blocks that occur before the first
                // RngRecord's startBlock. This is a workaround for Fog Ingest needing to mark the
                // blocks before the first run of Fog Ingest as missed blocks.
                //
                // This can be removed when Fog provides a guarantee that it won't report the blocks
                // before Fog Ingest was run for the first time as missed.
                guard range.lowerBound >= earliestRngStartBlockIndex else {
                    if range.upperBound <= earliestRngStartBlockIndex {
                        // Entire missed block range is before the earliest RngRecord's startBlock.
                        return nil
                    } else {
                        // Part of missed block range is before the ealiest RngRecord's startBlock,
                        // so we modify the missed blocks range.
                        return earliestRngStartBlockIndex..<range.upperBound
                    }
                }
                return range
            }
        }

        unscannedMissedBlocksRanges.append(contentsOf: missedBlocks)
    }

    func markBlocksAsScanned(blockRanges: [Range<UInt64>]) {
        for range in blockRanges {
            unscannedMissedBlocksRanges.removeAll(where: { $0 == range })
        }
    }

    private static func decryptSearchResult(
        _ searchResult: FogView_TxOutSearchResult,
        accountKey: AccountKey
    ) -> Result<FogView_TxOutRecord, ConnectionError> {
        FogViewUtils.decryptTxOutRecord(
            ciphertext: searchResult.ciphertext,
            accountKey: accountKey
        ).mapError { error in
            switch error {
            case .invalidInput:
                let errorMessage = "Could not decrypt TxOut returned from Fog View, ciphertext: " +
                    "\(redacting: searchResult.ciphertext.base64EncodedString()), error: " +
                    "\(error)"
                logger.error(errorMessage)
                return .invalidServerResponse(errorMessage)
            case .unsupportedVersion:
                let errorMessage = "Could not decrypt TxOut returned from Fog View, ciphertext: " +
                    "\(redacting: searchResult.ciphertext.base64EncodedString()), error: " +
                    "\(error)"
                logger.error(errorMessage)
                return .outdatedClient(errorMessage)
            }
        }
    }

    /// Filters out TxOuts that don't belong to this account.
    private static func ownedTxOuts(
        validating txOuts: [LedgerTxOut],
        accountKey: AccountKey
    ) -> [KnownTxOut] {
        let ownedTxOuts = txOuts.compactMap { txOut -> KnownTxOut? in
            guard let knownTxOut = txOut.decrypt(accountKey: accountKey) else {
                logger.warning(
                    "TxOut received from Fog View is not owned by this account. txOut: " +
                    "\(redacting: txOut.targetKey.data.hexEncodedString())",
                    logFunction: false)
                return nil
            }
            return knownTxOut
        }
        return ownedTxOuts
    }
}

struct FogSearchAttempt {
    fileprivate let rngSetSearchAttempt: FogRngSetSearchAttempt
    fileprivate let targetBlockCount: UInt64?

    var searchKeys: [FogSearchKey] { rngSetSearchAttempt.searchKeys }
}

extension LedgerTxOut {
    fileprivate static func make(txOutRecord: FogView_TxOutRecord, viewKey: RistrettoPrivate)
        -> Result<LedgerTxOut, ConnectionError>
    {
        guard let ledgerTxOut = LedgerTxOut(txOutRecord, viewKey: viewKey) else {
            let errorMessage = "Invalid TxOut returned from Fog View. TxOutRecord: " +
                "\(redacting: txOutRecord.serializedDataInfallible.base64EncodedString())"
            logger.error(errorMessage)
            return .failure(.invalidServerResponse(errorMessage))
        }
        return .success(ledgerTxOut)
    }
}
