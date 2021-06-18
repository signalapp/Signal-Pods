//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct TransactionSubmitter {
    private let consensusService: ConsensusService
    private let feeFetcher: BlockchainFeeFetcher

    init(consensusService: ConsensusService, feeFetcher: BlockchainFeeFetcher) {
        self.consensusService = consensusService
        self.feeFetcher = feeFetcher
    }

    func submitTransaction(
        _ transaction: Transaction,
        completion: @escaping (Result<(), TransactionSubmissionError>) -> Void
    ) {
        logger.info(
            "Submitting transaction... transaction: " +
            "\(redacting: transaction.serializedData.base64EncodedString())",
            logFunction: false)
        consensusService.proposeTx(External_Tx(transaction)) {
            switch $0 {
            case .success(let response):
                let responseResult = self.processResponse(response)
                if case .txFeeError = response.result {
                    self.feeFetcher.resetCache {
                        completion(responseResult)
                    }
                } else {
                    completion(responseResult)
                }
            case .failure(let error):
                completion(.failure(.connectionError(error)))
            }
        }
    }

    func processResponse(_ response: ConsensusCommon_ProposeTxResponse)
        -> Result<(), TransactionSubmissionError>
    {
        switch response.result {
        case .ok:
            return .success(())
        case .inputsProofsLengthMismatch, .noInputs, .tooManyInputs,
             .insufficientInputSignatures, .invalidInputSignature,
             .invalidTransactionSignature, .invalidRangeProof, .insufficientRingSize,
             .noOutputs, .tooManyOutputs, .excessiveRingSize, .duplicateRingElements,
             .unsortedRingElements, .unequalRingSizes, .unsortedKeyImages,
             .duplicateKeyImages, .duplicateOutputPublicKey, .missingTxOutMembershipProof,
             .invalidTxOutMembershipProof, .invalidRistrettoPublicKey,
             .tombstoneBlockExceeded, .invalidLedgerContext,
             .membershipProofValidationError, .keyError, .unsortedInputs:
            return .failure(.invalidTransaction())
        case .txFeeError:
            return .failure(.feeError())
        case .tombstoneBlockTooFar:
            return .failure(.tombstoneBlockTooFar())
        case .containsSpentKeyImage, .containsExistingOutputPublicKey:
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
        case .ledger:
            return .failure(.connectionError(
                .invalidServerResponse("Consensus.proposeTx returned ledger error")))
        case .UNRECOGNIZED(let resultCode):
            return .failure(.connectionError(.invalidServerResponse(
                "Consensus.proposeTx returned unrecognized result: \(resultCode)")))
        }
    }
}
