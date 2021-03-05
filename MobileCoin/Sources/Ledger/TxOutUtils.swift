//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum TxOutUtils {
    static func matchesAnySubaddress(
        commitment: Data32,
        maskedValue: UInt64,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> Bool {
        commitment.asMcBuffer { commitmentPtr in
            var mcAmount = McTxOutAmount(commitment: commitmentPtr, masked_value: maskedValue)
            return publicKey.asMcBuffer { publicKeyPtr in
                viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
                    var matches = false
                    // Safety: mc_tx_out_matches_any_subaddress is infallible when preconditions are
                    // upheld.
                    withMcInfallible {
                        mc_tx_out_matches_any_subaddress(
                            &mcAmount,
                            publicKeyPtr,
                            viewPrivateKeyPtr,
                            &matches)
                    }
                    return matches
                }
            }
        }
    }

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

    static func subaddressSpentPublicKey(
        targetKey: RistrettoPublic,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> RistrettoPublic {
        targetKey.asMcBuffer { targetKeyBufferPtr in
            publicKey.asMcBuffer { publicKeyBufferPtr in
                viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
                    let bytes: Data32
                    do {
                        bytes = try Data32.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                            mc_tx_out_get_subaddress_spend_public_key(
                                targetKeyBufferPtr,
                                publicKeyBufferPtr,
                                viewPrivateKeyPtr,
                                bufferPtr,
                                &errorPtr)
                        }).get()
                    } catch {
                        // Safety: This condition indicates a programming error and can only happen
                        // if arguments to mc_tx_out_get_subaddress_spend_public_key are supplied
                        // incorrectly.
                        logger.fatalError("\(Self.self).\(#function) error: \(error)")
                    }
                    // Safety: It's safe to skip validation because
                    // mc_tx_out_get_subaddress_spend_public_key should always return a valid
                    // RistrettoPublic on success.
                    return RistrettoPublic(skippingValidation: bytes)
                }
            }
        }
    }

    /// - Returns: `nil` when `viewPrivateKey` cannot unmask value, either because `viewPrivateKey`
    ///     does not own `TxOut` or because `TxOut` values are incongruent.
    static func value(
        commitment: Data32,
        maskedValue: UInt64,
        publicKey: RistrettoPublic,
        viewPrivateKey: RistrettoPrivate
    ) -> UInt64? {
        commitment.asMcBuffer { commitmentPtr in
            var mcAmount = McTxOutAmount(commitment: commitmentPtr, masked_value: maskedValue)
            return publicKey.asMcBuffer { publicKeyPtr in
                viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                    var valueOut: UInt64 = 0
                    switch withMcError({ errorPtr in
                        mc_tx_out_get_value(
                            &mcAmount,
                            publicKeyPtr,
                            viewKeyBufferPtr,
                            &valueOut,
                            &errorPtr)
                    }) {
                    case .success:
                        return valueOut
                    case .failure(let error):
                        switch error.errorCode {
                        case .encryptionFailure:
                            // Indicates either `commitment`/`maskedValue`/`publicKey` values are
                            // incongruent or `viewPrivateKey` does not own `TxOut`. However, it's
                            // not possible to determine which, only that the provided `commitment`
                            // doesn't match the computed commitment.
                            return nil
                        default:
                            // Safety: This condition indicates a programming error and can only
                            // happen if arguments to mc_tx_out_get_value are supplied incorrectly.
                            logger.fatalError("\(Self.self).\(#function) error: \(error)")
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
                            case .encryptionFailure:
                                // Indicates either `targetKey`/`publicKey` values are incongruent
                                //  or`viewPrivateKey`/`subaddressSpendPrivateKey` does not own
                                // `TxOut`. However, it's not possible to determine which, only that
                                // the provided `targetKey` doesn't match the computed target key
                                // (aka onetime public key).
                                return nil
                            default:
                                // Safety: This condition indicates a programming error and can only
                                // happen if arguments to mc_tx_out_get_key_image are supplied
                                // incorrectly.
                                logger.fatalError("\(Self.self).\(#function) error: \(error)")
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
