//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct TransactionSubmitter {
    private let consensusService: ConsensusService
    private let metaFetcher: BlockchainMetaFetcher
    private let syncCheckerLock: ReadWriteDispatchLock<FogSyncCheckable>

    init(
        consensusService: ConsensusService,
        metaFetcher: BlockchainMetaFetcher,
        syncChecker: ReadWriteDispatchLock<FogSyncCheckable>
    ) {
        self.consensusService = consensusService
        self.metaFetcher = metaFetcher
        self.syncCheckerLock = syncChecker
    }

    func submitTransaction(
        _ transaction: Transaction,
        completion: @escaping (Result<UInt64, SubmitTransactionError>) -> Void
    ) {
        logger.info(
            "Submitting transaction... transaction: " +
            "\(redacting: transaction.serializedData.base64EncodedString())",
            logFunction: false)

        consensusService.proposeTx(External_Tx(transaction)) {
            switch $0 {
            case .success(let response):
                // Consensus Block Index Cannot be less than 0
                let blockCount = response.blockCount > 0 ? response.blockCount - 1 : 0

                syncCheckerLock.writeSync {
                    $0.setConsensusHighestKnownBlock(blockCount)
                }

                let responseResult = self.processResponse(response, blockCount).mapError {
                    SubmitTransactionError(submissionError: $0, consensusBlockCount: blockCount)
                }

                if case .txFeeError = response.result {
                    self.metaFetcher.resetCache {
                        completion(responseResult)
                    }
                } else if metaFetcher.cachedBlockVersion() ?? 0 != response.blockVersion {
                    self.metaFetcher.resetCache {
                        completion(responseResult)
                    }
                } else {
                    completion(responseResult)
                }
            case .failure(let error):
                completion(.failure(
                    SubmitTransactionError(
                        submissionError: .connectionError(error),
                        consensusBlockCount: nil)))
            }
        }
    }

    func processResponse(_ response: ConsensusCommon_ProposeTxResponse, _ blockIndex: UInt64)
        -> Result<UInt64, TransactionSubmissionError>
    {
        switch response.result {
        case .ok:
            return .success(blockIndex)
        case .inputsProofsLengthMismatch, .noInputs, .tooManyInputs,
             .insufficientInputSignatures, .invalidInputSignature,
             .invalidTransactionSignature, .invalidRangeProof, .insufficientRingSize,
             .noOutputs, .tooManyOutputs, .excessiveRingSize, .duplicateRingElements,
             .unsortedRingElements, .unequalRingSizes, .unsortedKeyImages,
             .duplicateKeyImages, .duplicateOutputPublicKey, .missingTxOutMembershipProof,
             .invalidTxOutMembershipProof, .invalidRistrettoPublicKey,
             .tombstoneBlockExceeded, .invalidLedgerContext, .memosNotAllowed,
             .membershipProofValidationError, .keyError, .unsortedInputs,
             .tokenNotYetConfigured, .missingMaskedTokenID, .maskedTokenIDNotAllowed,
             .unsortedOutputs, .inputRulesNotAllowed, .inputRuleMissingRequiredOutput,
             .inputRuleMaxTombstoneBlockExceeded, .unknownMaskedAmountVersion,
             .inputRulePartialFill, .inputRuleInvalidAmountSharedSecret, .inputRuleTxOutConversion,
             .inputRuleAmount, .feeMapDigestMismatch:
            return .failure(.invalidTransaction(
                        "Error Code: \(response.result) " +
                        "(\(response.result.rawValue))"))
        case .txFeeError:
            return .failure(.feeError())
        case .tombstoneBlockTooFar:
            return .failure(.tombstoneBlockTooFar())
        case .missingMemo:
            return .failure(.missingMemo("Missing memo"))
        case .containsSpentKeyImage:
            // This exact Tx might have already been submitted (and succeeded), or else the
            // inputs were already spent by another Tx.
            //
            // Currently, consensus checks spent key images before checking if the outputs
            // already exist, which means submitting a Tx twice and submitting a Tx where
            // the inputs were already spent will both return a .containsSpentKeyImage
            // error, so we can't currently distinguish between the 2 situations.
            //
            // For the time being, we'll just return .inputsAlreadySpent and let the user
            // decide how they want to proceed. Note: performing a Transaction status check
            // can help disambiguate the situation.
            return .failure(.inputsAlreadySpent())
        case .containsExistingOutputPublicKey:
            return .failure(.outputAlreadyExists())
        case .ledger, .ledgerTxOutIndexOutOfBounds:
            return .failure(.connectionError(
                .invalidServerResponse("Consensus.proposeTx returned ledger error")))
        case .UNRECOGNIZED(let resultCode):
            return .failure(.connectionError(.invalidServerResponse(
                "Consensus.proposeTx returned unrecognized result: \(resultCode)")))
        }
    }
}

extension ConsensusCommon_ProposeTxResult {
    /**
     * The name of the enumeration (as written in case).
     */
    var name: String { String(describing: self) }

}
