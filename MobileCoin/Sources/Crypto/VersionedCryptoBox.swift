//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

enum VersionedCryptoBox {
    static func encrypt(
        plaintext: Data,
        publicKey: RistrettoPublic,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) throws -> Data {
        try publicKey.asMcBuffer { viewPublicKeyPtr in
            try plaintext.asMcBuffer { plaintextPtr in
                try withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
                    try Data(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_versioned_crypto_box_encrypt(
                            viewPublicKeyPtr,
                            plaintextPtr,
                            rngCallbackPtr,
                            bufferPtr,
                            &errorPtr)
                    })
                }
            }
        }
    }

    static func decrypt(
        ciphertext: Data,
        privateKey: RistrettoPrivate
    ) throws -> Data {
        try privateKey.asMcBuffer { privateKeyPtr in
            try ciphertext.asMcBuffer { ciphertextPtr in
                try Data(withEstimatedLengthMcMutableBuffer: ciphertext.count)
                { bufferPtr, errorPtr in
                    mc_versioned_crypto_box_decrypt(
                        privateKeyPtr,
                        ciphertextPtr,
                        bufferPtr,
                        &errorPtr)
                }
            }
        }
    }
}
