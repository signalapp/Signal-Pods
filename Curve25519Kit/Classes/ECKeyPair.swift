//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalCoreKit

public extension ECKeyPair {
    // TODO: Rename to publicKey(), rename existing publicKey() method to publicKeyData().
    func ecPublicKey() throws -> ECPublicKey {
        guard publicKey.count == ECCKeyLength else {
            throw OWSAssertionError("\(logTag) public key has invalid length")
        }

        // NOTE: we don't use ECPublicKey(serializedKeyData:) since the
        // key data should not have a type byte.
        return try ECPublicKey(keyData: publicKey)
    }

    // TODO: Rename to privateKey(), rename existing privateKey() method to privateKeyData().
    func ecPrivateKey() throws -> ECPrivateKey {
        guard privateKey.count == ECCKeyLength else {
            throw OWSAssertionError("\(logTag) private key has invalid length")
        }

        return try ECPrivateKey(keyData: privateKey)
    }
}
