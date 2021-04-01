//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum Mnemonic {
    public static var allWords: [String] = Bip39Utils.words(matchingPrefix: "")

    public static func entropy(fromMnemonic mnemonic: String) -> Result<Data, InvalidInputError> {
        Bip39Utils.entropy(fromMnemonic: mnemonic)
    }

    /// Entropy must be a multiple of 4 bytes and 16-32 bytes in length.
    public static func mnemonic(fromEntropy entropy: Data) -> Result<String, InvalidInputError> {
        Bip39Utils.mnemonic(fromEntropy: entropy)
    }

    public static func words(matchingPrefix prefix: String) -> [String] {
        Bip39Utils.words(matchingPrefix: prefix)
    }
}
