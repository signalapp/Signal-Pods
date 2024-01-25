//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct TransactionStatusTxOutChecker {
    private let account: ReadWriteDispatchLock<Account>
    private let fogUntrustedTxOutFetcher: FogUntrustedTxOutFetcher

    init(
        account: ReadWriteDispatchLock<Account>,
        fogUntrustedTxOutService: FogUntrustedTxOutService
    ) {
        self.account = account
        self.fogUntrustedTxOutFetcher =
            FogUntrustedTxOutFetcher(fogUntrustedTxOutService: fogUntrustedTxOutService)
    }

    func checkStatus(
        _ transaction: Transaction,
        completion: @escaping (Result<TransactionStatus, ConnectionError>) -> Void
    ) {
        logger.info(
            "Checking transaction status... transaction: " +
            "\(redacting: transaction.serializedData.base64EncodedString())",
            logFunction: false)
        checkAcceptedStatus(transaction) {
            completion($0.map { TransactionStatus($0) })
        }
    }

    func checkAcceptedStatus(
        _ transaction: Transaction,
        completion: @escaping (Result<Transaction.AcceptedStatus, ConnectionError>) -> Void
    ) {
        fogUntrustedTxOutFetcher.getTxOut(
            outputPublicKey: transaction.anyOutput.publicKey
        ) {
            completion($0.flatMap {
                Self.acceptedStatus(
                    of: transaction,
                    outputResult: $0,
                    outputBlockCount: $1)
            })
        }
    }

    private static func acceptedStatus(
        of transaction: Transaction,
        outputResult: FogLedger_TxOutResult,
        outputBlockCount: UInt64
    ) -> Result<Transaction.AcceptedStatus, ConnectionError> {
        // We assume the output public key is unique, therefore checking the existence of the output
        // is enough to confirm Tx was accepted.
        switch outputResult.resultCode {
        case .found:
            let block = BlockMetadata(index: outputResult.blockIndex,
                                      timestamp: outputResult.timestampDate)
            return .success(.accepted(block: block))
        case .notFound:
            if outputBlockCount >= transaction.tombstoneBlockIndex {
                return .success(.tombstoneBlockExceeded)
            } else {
                return .success(.notAccepted(knownToBeNotAcceptedTotalBlockCount: outputBlockCount))
            }
        case .malformedRequest, .databaseError, .UNRECOGNIZED:
            return .failure(.invalidServerResponse("Fog UntrustedTxOut result error: " +
                "\(outputResult.resultCode), response: \(outputResult)"))
        }
    }
}
