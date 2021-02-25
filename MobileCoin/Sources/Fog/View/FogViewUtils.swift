//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

enum FogViewUtils {
    static func encryptTxOutRecord(
        txOutRecord: FogView_TxOutRecord,
        publicAddress: PublicAddress,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) throws -> Data {
        let plaintext: Data
        do {
            plaintext = try txOutRecord.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            fatalError("Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }
        return try VersionedCryptoBox.encrypt(
            plaintext: plaintext,
            publicKey: publicAddress.viewPublicKeyTyped,
            rng: rng,
            rngContext: rngContext)
    }

    static func decryptTxOutRecord(
        ciphertext: Data,
        accountKey: AccountKey
    ) throws -> FogView_TxOutRecord {
        let decrypted = try VersionedCryptoBox.decrypt(
            ciphertext: ciphertext,
            privateKey: accountKey.subaddressViewPrivateKey)
        return try FogView_TxOutRecord(serializedData: decrypted)
    }
}
