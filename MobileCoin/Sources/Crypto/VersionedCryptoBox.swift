//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum VersionedCryptoBoxError: Error {
    case invalidInput(String)
    case unsupportedVersion(String)
}

extension VersionedCryptoBoxError: CustomStringConvertible {
    var description: String {
        "Versioned CryptoBox error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .unsupportedVersion(let reason):
                return "Unsupported version: \(reason)"
            }
        }()
    }
}

enum VersionedCryptoBox {
    static func encrypt(
        plaintext: Data,
        publicKey: RistrettoPublic,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<Data, InvalidInputError> {
        logger.info("")
        return publicKey.asMcBuffer { viewPublicKeyPtr in
            plaintext.asMcBuffer { plaintextPtr in
                withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                    Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_versioned_crypto_box_encrypt(
                            viewPublicKeyPtr,
                            plaintextPtr,
                            rngCallbackPtr,
                            bufferPtr,
                            &errorPtr)
                    }).mapError {
                        switch $0.errorCode {
                        case .aead:
                            return InvalidInputError($0.description)
                        default:
                            // Safety: mc_versioned_crypto_box_encrypt should not throw
                            // non-documented errors.
                            logger.fatalError(
                                "Unhandled LibMobileCoin error: \(redacting: $0.description)")
                        }
                    }
                }
            }
        }
    }

    static func decrypt(
        ciphertext: Data,
        privateKey: RistrettoPrivate
    ) -> Result<Data, VersionedCryptoBoxError> {
        logger.info("")
        return privateKey.asMcBuffer { privateKeyPtr in
            ciphertext.asMcBuffer { ciphertextPtr in
                Data.make(withEstimatedLengthMcMutableBuffer: ciphertext.count)
                { bufferPtr, errorPtr in
                    mc_versioned_crypto_box_decrypt(
                        privateKeyPtr,
                        ciphertextPtr,
                        bufferPtr,
                        &errorPtr)
                }.mapError {
                    switch $0.errorCode {
                    case .aead:
                        return .invalidInput(
                            "VersionedCryptoBox decryption error: \($0.description)")
                    case .unsupportedCryptoBoxVersion:
                        return .unsupportedVersion($0.description)
                    case .invalidInput:
                        logger.fatalError("error: \($0.description)")
                    default:
                        // Safety: mc_tx_out_get_key_image should not throw non-documented
                        // errors.
                        logger.fatalError(
                            "Unhandled LibMobileCoin error: \(redacting: $0.description)")
                    }
                }
            }
        }
    }
}
