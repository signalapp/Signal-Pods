//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum FogViewUtils {
    static func encryptTxOutRecord(
        txOutRecord: FogView_TxOutRecord,
        publicAddress: PublicAddress,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> Result<Data, InvalidInputError> {
        VersionedCryptoBox.encrypt(
            plaintext: txOutRecord.serializedDataInfallible,
            publicKey: publicAddress.viewPublicKeyTyped,
            rng: rng,
            rngContext: rngContext)
    }

    static func decryptTxOutRecord(
        ciphertext: Data,
        accountKey: AccountKey
    ) -> Result<FogView_TxOutRecord, VersionedCryptoBoxError> {
        VersionedCryptoBox.decrypt(
            ciphertext: ciphertext,
            privateKey: accountKey.subaddressViewPrivateKey
        ).flatMap { decrypted in
            guard let txOutRecord = try? FogView_TxOutRecord(serializedData: decrypted) else {
                return .failure(.invalidInput("FogView_TxOutRecord deserialization failed. " +
                    "serializedData: \(redacting: decrypted.base64EncodedString())"))
            }
            return .success(txOutRecord)
        }
    }
}
