//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum DefaultCryptoBox {
    public static func encrypt(
        plaintext: Data,
        publicAddress: PublicAddress
    ) -> Result<Data, InvalidInputError> {
        VersionedCryptoBox.encrypt(plaintext: plaintext,
                                   publicKey: publicAddress.spendPublicKeyTyped,
                                   rng: rngCallback,
                                   rngContext: MobileCoinXoshiroRng())
    }

    public static func decrypt(
        ciphertext: Data,
        accountKey: AccountKey
    ) -> Result<Data, VersionedCryptoBoxError> {
        VersionedCryptoBox.decrypt(ciphertext: ciphertext,
                                   privateKey: accountKey.subaddressSpendPrivateKey)
    }
}
