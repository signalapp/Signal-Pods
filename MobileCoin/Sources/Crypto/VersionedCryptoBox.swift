//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum VersionedCryptoBoxError: Error {
    case invalidInput(String)
    case unsupportedVersion(String)
}

enum VersionedCryptoBox {
    static func encrypt(
        plaintext: Data,
        publicKey: RistrettoPublic,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<Data, InvalidInputError> {
        publicKey.asMcBuffer { viewPublicKeyPtr in
            plaintext.asMcBuffer { plaintextPtr in
                withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                    Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_versioned_crypto_box_encrypt(
                            viewPublicKeyPtr,
                            plaintextPtr,
                            rngCallbackPtr,
                            bufferPtr,
                            &errorPtr)
                    }).mapError { InvalidInputError(String(describing: $0)) }
                }
            }
        }
    }

    static func decrypt(
        ciphertext: Data,
        privateKey: RistrettoPrivate
    ) -> Result<Data, VersionedCryptoBoxError> {
        privateKey.asMcBuffer { privateKeyPtr in
            ciphertext.asMcBuffer { ciphertextPtr in
                Data.make(withEstimatedLengthMcMutableBuffer: ciphertext.count)
                { bufferPtr, errorPtr in
                    mc_versioned_crypto_box_decrypt(
                        privateKeyPtr,
                        ciphertextPtr,
                        bufferPtr,
                        &errorPtr)
                }.mapError { .invalidInput("VersionedCryptoBox decryption error: \($0)") }
            }
        }
    }
}
