//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogView {
    private let rngSet = FogRngSet()

    var allRngTxOutsFoundBlockCount: UInt64 {
        rngSet.knownBlockCount
    }

    var allRngRecordsKnownBlockCount: UInt64 {
        rngSet.rngRecordsKnownBlockCount
    }

    func searchAttempt(
        requestedBlockCount: UInt64?,
        numOutputs: Int,
        minOutputsPerSelectedRng: Int
    ) throws -> FogSearchAttempt {
        try rngSet.searchAttempt(
            requestedBlockCount: requestedBlockCount,
            numOutputs: numOutputs,
            minOutputsPerSelectedRng: minOutputsPerSelectedRng)
    }

    func processSearchResult(
        accountKey: AccountKey,
        searchAttempt: FogSearchAttempt,
        response: FogView_QueryResponse
    ) throws -> [KnownTxOut] {
        let encryptedTxOuts = try rngSet.processSearchResults(
            searchAttempt: searchAttempt,
            accountKey: accountKey,
            rngsRecords: response.rngs,
            decommissionedRngs: response.decommissionedIngestInvocations,
            txOutResults: response.txOutSearchResults,
            blockCount: response.highestProcessedBlockCount)

        let txOutHits: [LedgerTxOut] = encryptedTxOuts.compactMap {
            do {
                let txOutRecord = try FogViewUtils.decryptTxOutRecord(
                    ciphertext: $0.ciphertext,
                    accountKey: accountKey)
                return LedgerTxOut(txOutRecord)
            } catch {
                print("Warning: could not decrypt TxOut returned from Fog View, " +
                    "base58 ciphertext: \($0.ciphertext.base64EncodedString()), " +
                    "error: \(error)")
                return nil
            }
        }

        return txOutHits.compactMap { txOut in
            guard let knownTxOut = KnownTxOut(txOut, accountKey: accountKey) else {
                print("Warning: TxOut received from Fog View is not owned by this account.")
                return nil
            }
            return knownTxOut
        }
    }
}
