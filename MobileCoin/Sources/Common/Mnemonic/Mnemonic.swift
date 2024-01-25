//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct Mnemonic {
    public static let allWords = Bip39Utils.words(matchingPrefix: "")

    /// Entropy must be a multiple of 4 bytes and 16-32 bytes in length.
    public static func mnemonic(fromEntropy entropy: Data) -> Result<String, InvalidInputError> {
        Bip39Utils.mnemonic(fromEntropy: entropy).map { $0.phrase }
    }

    public static func entropy(fromMnemonic mnemonic: String) -> Result<Data, InvalidInputError> {
        Bip39Utils.entropy(fromMnemonic: mnemonic)
    }

    public static func words(matchingPrefix prefix: String) -> [String] {
        Bip39Utils.words(matchingPrefix: prefix)
    }

    let phrase: String

    init(phraseSkippingValidation phrase: String) {
        self.phrase = phrase
    }
}
