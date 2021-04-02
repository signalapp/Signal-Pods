//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

final class FogView {
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

    func searchAttempt(
        requestedBlockCount: UInt64?,
        numOutputs: PositiveInt,
        minOutputsPerSelectedRng: Int
    ) -> FogSearchAttempt {
        logger.info("")
        return rngSet.searchAttempt(
            requestedBlockCount: requestedBlockCount,
            numOutputs: numOutputs,
            minOutputsPerSelectedRng: minOutputsPerSelectedRng)
    }

    func processQueryResponse(
        _ queryResponse: FogView_QueryResponse,
        searchAttempt: FogSearchAttempt,
        accountKey: AccountKey
    ) -> Result<[KnownTxOut], ConnectionError> {
        logger.info("")
        return rngSet.processRngs(queryResponse: queryResponse, accountKey: accountKey).flatMap {
            processMissedBlockRanges(queryResponse.missedBlockRanges)

            if queryResponse.nextStartFromUserEventID > nextStartFromUserEventId {
                // We set this only after we've processed the info in `QueryResponse` that's
                // considered an event, which currently includes `NewRngRecord`,
                // `DecommissionIngestInvocation`, and `MissingBlocks`. (See `FogUserEvent` in the
                // Fog repo for the canonical list.)
                nextStartFromUserEventId = queryResponse.nextStartFromUserEventID
            }

            return rngSet.processTxOutSearchResults(
                queryResponse: queryResponse,
                searchAttempt: searchAttempt
            ).flatMap { searchResults in
                searchResults.map { searchResult in
                    Self.decryptSearchResult(searchResult, accountKey: accountKey)
                }.collectResult().map { decryptedTxOuts in
                    // Filter out TxOuts that don't belong to this account.
                    decryptedTxOuts.compactMap { txOut in
                        guard let knownTxOut = KnownTxOut(txOut, accountKey: accountKey) else {
                            logger.warning(
                                "TxOut received from Fog View is not owned by this account.")
                            return nil
                        }
                        return knownTxOut
                    }
                }
            }
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
    ) -> Result<LedgerTxOut, ConnectionError> {
        logger.info("")
        return FogViewUtils.decryptTxOutRecord(
            ciphertext: searchResult.ciphertext,
            accountKey: accountKey
        ).mapError { error in
            switch error {
            case .invalidInput(let reason):
                logger.warning(
                    "Warning: could not decrypt TxOut returned from Fog View, base64 " +
                        "ciphertext: \(redacting: searchResult.ciphertext.base64EncodedString())," +
                        " error: \(error)")
                return .invalidServerResponse(reason)
            case .unsupportedVersion(let reason):
                logger.warning(
                    "Warning: could not decrypt TxOut returned from Fog View, base64 " +
                        "ciphertext: \(redacting: searchResult.ciphertext.base64EncodedString())," +
                        " error: \(error)")
                return .outdatedClient(reason)
            }
        }.flatMap { txOutRecord in
            ledgerTxOut(from: txOutRecord)
        }
    }

    private static func ledgerTxOut(from txOutRecord: FogView_TxOutRecord)
        -> Result<LedgerTxOut, ConnectionError>
    {
        guard let ledgerTxOut = LedgerTxOut(txOutRecord) else {
            let serializedTxOutRecord: Data
            do {
                serializedTxOutRecord = try txOutRecord.serializedData()
            } catch {
                // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
                logger.fatalError("Protobuf serialization failed: \(redacting: error)")
            }
            logger.info("Invalid TxOut returned from Fog View.")
            return .failure(.invalidServerResponse(
                "Invalid TxOut returned from Fog View. Base64-encoded TxOutRecord: " +
                "\(serializedTxOutRecord.base64EncodedString())"))
        }
        return .success(ledgerTxOut)
    }
}
