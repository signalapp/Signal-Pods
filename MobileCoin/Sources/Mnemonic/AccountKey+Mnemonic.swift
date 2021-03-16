//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension AccountKey {
    public static func rootEntropy(fromMnemonic mnemonic: String, accountIndex: UInt32)
        -> Result<Data, InvalidInputError>
    {
        Bip39Utils.seed(fromMnemonic: mnemonic).map { seed in
            Bip44Utils.ed25519PrivateKey(fromSeed: seed, accountIndex: accountIndex).data
        }
    }
}
