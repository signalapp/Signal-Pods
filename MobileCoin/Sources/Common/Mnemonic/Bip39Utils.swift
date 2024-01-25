//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum Bip39Utils {
    static func mnemonic(fromEntropy entropy: Data32) -> Mnemonic {
        let mnemonic = entropy.asMcBuffer { entropyPtr in
            String(mcString:
                withMcInfallibleReturningOptional { mc_bip39_mnemonic_from_entropy(entropyPtr) })
        }
        return Mnemonic(phraseSkippingValidation: mnemonic)
    }

    /// Entropy must be a multiple of 4 bytes and 16-32 bytes in length.
    static func mnemonic(fromEntropy entropy: Data) -> Result<Mnemonic, InvalidInputError> {
        guard entropy.count % 4 == 0 else {
            return .failure(InvalidInputError("BIP39 error: entropy must be a multiple of 4 bytes"))
        }
        guard entropy.count >= 16 && entropy.count <= 32 else {
            return .failure(InvalidInputError(
                "BIP39 error: entropy must be between 16 and 32 bytes, inclusive"))
        }
        let mnemonic = entropy.asMcBuffer { entropyPtr in
            String(mcString:
                withMcInfallibleReturningOptional { mc_bip39_mnemonic_from_entropy(entropyPtr) })
        }
        return .success(Mnemonic(phraseSkippingValidation: mnemonic))
    }

    static func words(matchingPrefix prefix: String) -> [String] {
        let wordsList =
            String(mcString: withMcInfallibleReturningOptional { mc_bip39_words_by_prefix(prefix) })
        return wordsList.split(separator: ",").map { String($0) }
    }

    static func entropy(fromMnemonic mnemonic: Mnemonic) -> Data {
        switch Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
            mc_bip39_entropy_from_mnemonic(mnemonic.phrase, bufferPtr, &errorPtr)
        }) {
        case .success(let entropy):
            return entropy
        case .failure(let error):
            switch error.errorCode {
            case .invalidInput:
                // Safety: mc_bip39_entropy_from_mnemonic should not return invalidInput as long as
                // `mnemonic` is well-formed.
                logger.fatalError(
                    "BIP39: error deriving entropy from mnemonic: \(redacting: error.description)")
            default:
                // Safety: mc_bip39_entropy_from_mnemonic should not throw non-documented errors.
                logger.fatalError("Unhandled LibMobileCoin error: \(redacting: error)")
            }
        }
    }

    static func entropy(fromMnemonic mnemonic: String) -> Result<Data, InvalidInputError> {
        Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
            mc_bip39_entropy_from_mnemonic(mnemonic, bufferPtr, &errorPtr)
        }).mapError {
            switch $0.errorCode {
            case .invalidInput:
                return InvalidInputError(
                    "BIP39: error deriving entropy from mnemonic: \(redacting: $0.description)")
            default:
                // Safety: mc_bip39_entropy_from_mnemonic should not throw non-documented errors.
                logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
            }
        }
    }
}
