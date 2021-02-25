//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct TransactionStatusChecker {
    private let fogUntrustedTxOutFetcher: FogUntrustedTxOutFetcher
    private let fogKeyImageChecker: FogKeyImageChecker

    init(
        fogUntrustedTxOutService: FogUntrustedTxOutService,
        fogKeyImageService: FogKeyImageService,
        targetQueue: DispatchQueue?
    ) {
        self.fogUntrustedTxOutFetcher = FogUntrustedTxOutFetcher(
            fogUntrustedTxOutService: fogUntrustedTxOutService,
            targetQueue: targetQueue)
        self.fogKeyImageChecker = FogKeyImageChecker(
            fogKeyImageService: fogKeyImageService,
            targetQueue: targetQueue)
    }

    func checkStatus(
        _ transaction: Transaction,
        completion: @escaping (Result<TransactionStatus, Error>) -> Void
    ) {
        checkAcceptedStatus(transaction) {
            completion($0.map { TransactionStatus($0) })
        }
    }

    func checkAcceptedStatus(
        _ transaction: Transaction,
        completion: @escaping (Result<Transaction.AcceptedStatus, Error>) -> Void
    ) {
        performAsync(body1: { callback in
            fogUntrustedTxOutFetcher.getOutputs(for: transaction, completion: callback)
        }, body2: { callback in
            fogKeyImageChecker.checkInputKeyImages(for: transaction, completion: callback)
        }, completion: {
            completion($0.flatMap {
                try Self.acceptedStatus(
                    of: transaction,
                    keyImageSpentStatus: $0.1,
                    outputResult: $0.0.result,
                    outputBlockCount: $0.0.blockCount)
            })
        })
    }

    private static func acceptedStatus(
        of transaction: Transaction,
        keyImageSpentStatus: KeyImage.SpentStatus,
        outputResult: FogLedger_TxOutResult,
        outputBlockCount: UInt64
    ) throws -> Transaction.AcceptedStatus {
        // We assume the output public key is unique, therefore checking the existence of the output
        // is enough to confirm Tx was accepted. However, at the moment we still need the key image
        // check in order to get the block in which the Tx was accepted.
        switch outputResult.resultCode {
        case .found:
            switch keyImageSpentStatus {
            case .spent(block: let block):
                return .accepted(block: block)
            case .unspent(knownToBeUnspentBlockCount: let knownToBeUnspentBlockCount):
                // Output exists but key image server hasn't received it yet. At the moment, this
                // means we must return .notAccepted since we don't know which block it was accepted
                // in.
                return .notAccepted(knownToBeNotAcceptedTotalBlockCount: knownToBeUnspentBlockCount)
            }
        case .notFound:
            if outputBlockCount >= transaction.tombstoneBlockIndex {
                return .tombstoneBlockExceeded
            }
            // Without confirming the output exists in the ledger, we can't be certain that the key
            // image wasn't spent by another Tx (possibly by a different client using the same
            // account key).
            switch keyImageSpentStatus {
            case .spent(block: let block):
                if outputBlockCount > block.index {
                    // The output doexn't exist at the block height where the input was spent, so we
                    // know that the Tx failed.
                    return .inputSpent
                } else {
                    // The input was spent, but we don't yet know whether it was spent by this Tx or
                    // not.
                    return .notAccepted(knownToBeNotAcceptedTotalBlockCount: outputBlockCount)
                }
            case .unspent(knownToBeUnspentBlockCount: let knownToBeUnspentBlockCount):
                if knownToBeUnspentBlockCount >= transaction.tombstoneBlockIndex {
                    return .tombstoneBlockExceeded
                } else {
                    return .notAccepted(knownToBeNotAcceptedTotalBlockCount:
                        max(outputBlockCount, knownToBeUnspentBlockCount))
                }
            }
        case .malformedRequest, .databaseError, .UNRECOGNIZED:
            throw ConnectionFailure("Fog UntrustedTxOut result error: " +
                "\(outputResult.resultCode), response: \(outputResult)")
        }
    }
}
