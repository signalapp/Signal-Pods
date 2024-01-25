//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct TransactionStatusChecker {
    private let account: ReadWriteDispatchLock<Account>
    private let fogUntrustedTxOutFetcher: FogUntrustedTxOutFetcher
    private let fogKeyImageChecker: FogKeyImageChecker

    init(
        account: ReadWriteDispatchLock<Account>,
        fogUntrustedTxOutService: FogUntrustedTxOutService,
        fogKeyImageService: FogKeyImageService,
        targetQueue: DispatchQueue?
    ) {
        self.account = account
        self.fogUntrustedTxOutFetcher =
            FogUntrustedTxOutFetcher(fogUntrustedTxOutService: fogUntrustedTxOutService)
        self.fogKeyImageChecker =
            FogKeyImageChecker(
                    fogKeyImageService: fogKeyImageService,
                    targetQueue: targetQueue,
                    syncChecker: account.accessWithoutLocking.syncCheckerLock)
    }

    func checkStatus(
        _ transaction: Transaction,
        requireInBalance: Bool = true,
        completion: @escaping (Result<TransactionStatus, ConnectionError>) -> Void
    ) {
        logger.info(
            "Checking transaction status... transaction: " +
            "\(redacting: transaction.serializedData.base64EncodedString())",
            logFunction: false)
        checkAcceptedStatus(transaction) {
            completion($0.map {
                let status = TransactionStatus($0)
                switch status {
                case .accepted(block: let block):
                    // Make sure we only return success if it will also be reflected in the balance,
                    // otherwise, feign ignorance.
                    guard !requireInBalance ||
                            (block.index < self.account.readSync({ $0.knowableBlockCount })) else {
                        return .unknown
                    }
                    return status
                case .unknown, .failed:
                    return status
                }
            })
        }
    }

    func checkAcceptedStatus(
        _ transaction: Transaction,
        completion: @escaping (Result<Transaction.AcceptedStatus, ConnectionError>) -> Void
    ) {
        performAsync(body1: { callback in
            fogUntrustedTxOutFetcher.getTxOut(
                outputPublicKey: transaction.anyOutput.publicKey,
                completion: callback)
        }, body2: { callback in
            fogKeyImageChecker.checkKeyImage(
                keyImage: transaction.anyInputKeyImage,
                completion: callback)
        }, completion: {
            completion($0.flatMap {
                Self.acceptedStatus(
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
    ) -> Result<Transaction.AcceptedStatus, ConnectionError> {
        // We assume the output public key is unique, therefore checking the existence of the output
        // is enough to confirm Tx was accepted. However, at the moment we still need the key image
        // check in order to get the block in which the Tx was accepted.
        switch outputResult.resultCode {
        case .found:
            switch keyImageSpentStatus {
            case .spent(block: let block):
                return .success(.accepted(block: block))
            case .unspent(knownToBeUnspentBlockCount: let knownToBeUnspentBlockCount):
                // Output exists but key image server hasn't received it yet. At the moment, this
                // means we must return .notAccepted since we don't know which block it was accepted
                // in.
                return .success(
                    .notAccepted(knownToBeNotAcceptedTotalBlockCount: knownToBeUnspentBlockCount))
            }
        case .notFound:
            if outputBlockCount >= transaction.tombstoneBlockIndex {
                return .success(.tombstoneBlockExceeded)
            }
            // Without confirming the output exists in the ledger, we can't be certain that the key
            // image wasn't spent by another Tx (possibly by a different client using the same
            // account key).
            switch keyImageSpentStatus {
            case .spent(block: let block):
                if outputBlockCount > block.index {
                    // The output doexn't exist at the block height where the input was spent, so we
                    // know that the Tx failed.
                    return .success(.inputSpent)
                } else {
                    // The input was spent, but we don't yet know whether it was spent by this Tx or
                    // not.
                    return .success(
                        .notAccepted(knownToBeNotAcceptedTotalBlockCount: outputBlockCount))
                }
            case .unspent(knownToBeUnspentBlockCount: let knownToBeUnspentBlockCount):
                if knownToBeUnspentBlockCount >= transaction.tombstoneBlockIndex {
                    return .success(.tombstoneBlockExceeded)
                } else {
                    return .success(.notAccepted(knownToBeNotAcceptedTotalBlockCount:
                        max(outputBlockCount, knownToBeUnspentBlockCount)))
                }
            }
        case .malformedRequest, .databaseError, .UNRECOGNIZED:
            return .failure(.invalidServerResponse("Fog UntrustedTxOut result error: " +
                "\(outputResult.resultCode), response: \(outputResult)"))
        }
    }
}
