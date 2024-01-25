//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable closure_body_length

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum TxOutUtils {
    static func matchesSubaddress(
        targetKey: RistrettoPublic,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate
    ) -> Bool {
        targetKey.asMcBuffer { targetKeyBufferPtr in
            publicKey.asMcBuffer { publicKeyBufferPtr in
                viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                    subaddressSpendPrivateKey.asMcBuffer { spendPrivateKeyBufferPtr in
                        var matches = false
                        // Safety: mc_tx_out_matches_subaddress is infallible when preconditions are
                        // upheld.
                        withMcInfallible {
                            mc_tx_out_matches_subaddress(
                                targetKeyBufferPtr,
                                publicKeyBufferPtr,
                                viewKeyBufferPtr,
                                spendPrivateKeyBufferPtr,
                                &matches)
                        }
                        return matches
                    }
                }
            }
        }
    }

    static func sharedSecret(
        viewPrivateKey: RistrettoPrivate,
        publicKey: RistrettoPublic
    ) -> RistrettoPrivate? {
        publicKey.asMcBuffer { publicKeyBufferPtr in
            viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
                switch Data32.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                    mc_tx_out_get_shared_secret(
                        viewPrivateKeyPtr,
                        publicKeyBufferPtr,
                        bufferPtr,
                        &errorPtr)
                }) {
                case .success(let bytes):
                    // Safety: It's safe to skip validation because
                    // mc_tx_out_get_subaddress_spend_public_key should always return a valid
                    // RistrettoPrivate on success.
                    return RistrettoPrivate(skippingValidation: bytes)
                case .failure(let error):
                    switch error.errorCode {
                    case .invalidInput:
                        // Safety: This condition indicates a programming error and can only
                        // happen if arguments to mc_tx_out_get_shared_secret are
                        // supplied incorrectly.
                        logger.warning("error: \(redacting: error)")
                        return nil
                    default:
                        // Safety: mc_tx_out_get_shared_secret should not throw
                        // non-documented errors.
                        logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                        return nil
                    }
                }
            }
        }
    }

    static func reconstructCommitment(
        maskedAmount: MaskedAmount,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> Data32? {
        reconstructCommitment(
            maskedValue: maskedAmount.maskedValue,
            maskedTokenId: maskedAmount.maskedTokenId,
            maskedAmountVersion: maskedAmount.version,
            publicKey: publicKey,
            viewPrivateKey: viewPrivateKey)
    }

    static func reconstructCommitment(
        maskedValue: UInt64,
        maskedTokenId: Data,
        maskedAmountVersion: MaskedAmount.Version,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> Data32? {
        maskedTokenId.asMcBuffer { maskedTokenIdBufferPtr in
            publicKey.asMcBuffer { publicKeyBufferPtr in
                viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
                    var mcAmount = McTxOutMaskedAmount(
                        masked_value: maskedValue,
                        masked_token_id: maskedTokenIdBufferPtr,
                        version: maskedAmountVersion.libmobilecoin_version)
                    switch Data32.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_tx_out_reconstruct_commitment(
                            &mcAmount,
                            publicKeyBufferPtr,
                            viewPrivateKeyPtr,
                            bufferPtr,
                            &errorPtr)
                    }) {
                    case .success(let bytes):
                        // Safety: It's safe to skip validation because
                        // mc_tx_out_reconstruct_commitment should always return a valid
                        // RistrettoPublic on success.
                        return bytes as Data32
                    case .failure(let error):
                        switch error.errorCode {
                        case .invalidInput:
                            // Safety: This condition indicates a programming error and can only
                            // happen if arguments to mc_tx_out_reconstruct_commitment are
                            // supplied incorrectly.
                            logger.warning("error: \(redacting: error)")
                            return nil
                        default:
                            // Safety: mc_tx_out_reconstruct_commitment should not throw
                            // non-documented errors.
                            logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                            return nil
                        }
                    }
                }
            }
        }
    }

    static func decryptEMemoPayload(
        encryptedMemo: Data66,
        txOutPublicKey: RistrettoPublic,
        accountKey: AccountKey
    ) -> Data66? {
        accountKey.viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            encryptedMemo.asMcBuffer { eMemoPtr in
                txOutPublicKey.asMcBuffer { publicKeyPtr in
                    switch Data66.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_memo_decrypt_e_memo_payload(
                            eMemoPtr,
                            publicKeyPtr,
                            viewPrivateKeyPtr,
                            bufferPtr,
                            &errorPtr)
                    }) {
                    case .success(let bytes):
                        // Safety: It's safe to skip validation because
                        // mc_tx_out_reconstruct_commitment should always return a valid
                        // RistrettoPublic on success.
                        return bytes as Data66
                    case .failure(let error):
                        switch error.errorCode {
                        case .invalidInput:
                            // Safety: This condition indicates a programming error and can only
                            // happen if arguments to mc_tx_out_reconstruct_commitment are
                            // supplied incorrectly.
                            logger.warning("error: \(redacting: error)")
                            return nil
                        default:
                            // Safety: mc_tx_out_reconstruct_commitment should not throw
                            // non-documented errors.
                            logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                            return nil
                        }
                    }
                }
            }
        }
    }

    static func calculateCrc32(
        from commitment: Data32
    ) -> UInt32? {
        commitment.asMcBuffer { commitmentPtr in
            var crc32: UInt32 = 0
            switch withMcError({ errorPtr in
                mc_tx_out_commitment_crc32(
                    commitmentPtr,
                    &crc32,
                    &errorPtr)
            }) {
            case .success:
                return crc32
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to mc_tx_out_commitment_crc32 are supplied incorrectly.
                    logger.assertionFailure("error: \(redacting: error)")
                    return nil
                default:
                    // Safety: mc_tx_out_commitment_crc32 should not throw nondocumented errors.
                    logger.assertionFailure("Unhandled LibMobileCoin error: \(redacting: error)")
                    return nil
                }
            }
        }
    }

    static func subaddressSpentPublicKey(
        targetKey: RistrettoPublic,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> RistrettoPublic {
        targetKey.asMcBuffer { targetKeyBufferPtr in
            publicKey.asMcBuffer { publicKeyBufferPtr in
                viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
                    switch Data32.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_tx_out_get_subaddress_spend_public_key(
                            targetKeyBufferPtr,
                            publicKeyBufferPtr,
                            viewPrivateKeyPtr,
                            bufferPtr,
                            &errorPtr)
                    }) {
                    case .success(let bytes):
                        // Safety: It's safe to skip validation because
                        // mc_tx_out_get_subaddress_spend_public_key should always return a valid
                        // RistrettoPublic on success.
                        return RistrettoPublic(skippingValidation: bytes)
                    case .failure(let error):
                        switch error.errorCode {
                        case .invalidInput:
                            // Safety: This condition indicates a programming error and can only
                            // happen if arguments to mc_tx_out_get_subaddress_spend_public_key are
                            // supplied incorrectly.
                            logger.fatalError("error: \(redacting: error)")
                        default:
                            // Safety: mc_fog_resolver_add_report_response should not throw
                            // non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: error)")
                        }
                    }
                }
            }
        }
    }

    /// - Returns: `nil` when `viewPrivateKey` cannot unmask value, either because `viewPrivateKey`
    ///     does not own `TxOut` or because `TxOut` values are incongruent.
    static func amount(
        maskedAmount: MaskedAmount,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> Amount? {
        var mcTxOutAmount = McTxOutAmount()
        return maskedAmount.maskedTokenId.asMcBuffer { maskedTokenIdBufferPtr in
            publicKey.asMcBuffer { publicKeyPtr in
                viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                    var mcMaskedAmount = McTxOutMaskedAmount(
                        masked_value: maskedAmount.maskedValue,
                        masked_token_id: maskedTokenIdBufferPtr,
                        version: maskedAmount.libmobilecoin_version)
                    switch withMcError({ errorPtr in
                        mc_tx_out_get_amount(
                            &mcMaskedAmount,
                            publicKeyPtr,
                            viewKeyBufferPtr,
                            &mcTxOutAmount,
                            &errorPtr)
                    }) {
                    case .success:
                        return Amount(mcTxOutAmount)
                    case .failure(let error):
                        switch error.errorCode {
                        case .transactionCrypto:
                            // Indicates either `commitment`/`maskedValue`/`publicKey` values are
                            // incongruent or `viewPrivateKey` does not own `TxOut`. However, it's
                            // not possible to determine which, only that the provided `commitment`
                            // doesn't match the computed commitment.
                            return nil
                        case .invalidInput:
                            // Safety: This condition indicates a programming error and can only
                            // happen if arguments to mc_tx_out_get_value are supplied incorrectly.
                            logger.fatalError("error: \(redacting: error)")
                        default:
                            // Safety: mc_tx_out_get_value should not throw non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: error)")
                        }
                    }
                }
            }
        }
    }

    /// - Returns: `nil` when a valid `KeyImage` cannot be constructed, either because
    ///     `viewPrivateKey`/`subaddressSpendPrivateKey` do not own `TxOut` or because `TxOut`
    ///     values are incongruent.
    static func keyImage(
        targetKey: RistrettoPublic,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate
    ) -> KeyImage? {
        targetKey.asMcBuffer { targetKeyPtr in
            publicKey.asMcBuffer { publicKeyPtr in
                viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                    subaddressSpendPrivateKey.asMcBuffer { spendKeyBufferPtr in
                        switch Data32.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                            mc_tx_out_get_key_image(
                                targetKeyPtr,
                                publicKeyPtr,
                                viewKeyBufferPtr,
                                spendKeyBufferPtr,
                                bufferPtr,
                                &errorPtr)
                        }) {
                        case .success(let keyImageData):
                            return KeyImage(keyImageData)
                        case .failure(let error):
                            switch  error.errorCode {
                            case .transactionCrypto:
                                // Indicates either `targetKey`/`publicKey` values are incongruent
                                //  or`viewPrivateKey`/`subaddressSpendPrivateKey` does not own
                                // `TxOut`. However, it's not possible to determine which, only that
                                // the provided `targetKey` doesn't match the computed target key
                                // (aka onetime public key).
                                return nil
                            case .invalidInput:
                                // Safety: This condition indicates a programming error and can only
                                // happen if arguments to mc_tx_out_get_key_image are supplied
                                // incorrectly.
                                logger.fatalError("error: \(redacting: error)")
                            default:
                                // Safety: mc_tx_out_get_key_image should not throw non-documented
                                // errors.
                                logger.fatalError(
                                    "Unhandled LibMobileCoin error: \(redacting: error)")
                            }
                        }
                    }
                }
            }
        }
    }

    static func validateConfirmationNumber(
        publicKey: RistrettoPublic,
        confirmationNumber: TxOutConfirmationNumber,
        viewPrivateKey: RistrettoPrivate
    ) -> Bool {
        publicKey.asMcBuffer { publicKeyPtr in
            confirmationNumber.asMcBuffer { confirmationNumberPtr in
                viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                    var result = false
                    // Safety: mc_tx_out_validate_confirmation_number is infallible when
                    // preconditions are upheld.
                    withMcInfallible {
                        mc_tx_out_validate_confirmation_number(
                            publicKeyPtr,
                            confirmationNumberPtr,
                            viewKeyBufferPtr,
                            &result)
                    }
                    return result
                }
            }
        }
    }
}
