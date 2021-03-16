//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

final class FogView {
    private let rngSet = FogRngSet()

    var earliestRngStartBlockIndex: UInt64? {
        rngSet.earliestRngRecordStartBlockIndex
    }

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
        rngSet.searchAttempt(
            requestedBlockCount: requestedBlockCount,
            numOutputs: numOutputs,
            minOutputsPerSelectedRng: minOutputsPerSelectedRng)
    }

    func processQueryResponse(
        searchAttempt: FogSearchAttempt,
        response: FogView_QueryResponse,
        accountKey: AccountKey
    ) -> Result<[KnownTxOut], ConnectionError> {
        rngSet.processQueryResponse(
            searchAttempt: searchAttempt,
            queryResponse: response,
            accountKey: accountKey
        ).flatMap { searchResults in
            searchResults.map { searchResult in
                Self.decryptSearchResult(searchResult: searchResult, accountKey: accountKey)
            }.collectResult().map { decryptedTxOuts in
                // Filter out TxOuts that don't belong to this account.
                decryptedTxOuts.compactMap { txOut in
                    guard let knownTxOut = KnownTxOut(txOut, accountKey: accountKey) else {
                        print("Warning: TxOut received from Fog View is not owned by this account.")
                        return nil
                    }
                    return knownTxOut
                }
            }
        }
    }

    private static func decryptSearchResult(
        searchResult: FogView_TxOutSearchResult,
        accountKey: AccountKey
    ) -> Result<LedgerTxOut, ConnectionError> {
        FogViewUtils.decryptTxOutRecord(
            ciphertext: searchResult.ciphertext,
            accountKey: accountKey
        ).mapError { error in
            switch error {
            case .invalidInput(let reason):
                print("Warning: could not decrypt TxOut returned from Fog View, base64 " +
                    "ciphertext: \(searchResult.ciphertext.base64EncodedString()), " +
                    "error: \(error)")
                return .invalidServerResponse(reason)
            case .unsupportedVersion(let reason):
                return .outdatedClient(reason)
            }
        }.flatMap { txOutRecord in
            guard let ledgerTxOut = LedgerTxOut(txOutRecord) else {
                let serializedTxOutRecord: Data
                do {
                    serializedTxOutRecord = try txOutRecord.serializedData()
                } catch {
                    // Safety: Protobuf binary serialization is no fail when not using proto2 or
                    // `Any`.
                    logger.fatalError(
                        "Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
                }
                return .failure(.invalidServerResponse(
                    "Invalid TxOut returned from Fog View. Base64-encoded TxOutRecord: " +
                    "\(serializedTxOutRecord.base64EncodedString())"))
            }
            return .success(ledgerTxOut)
        }
    }
}
