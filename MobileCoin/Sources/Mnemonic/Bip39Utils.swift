//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum Bip39Utils {
    static func entropy(fromMnemonic mnemonic: String) -> Result<Data, InvalidInputError> {
        Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
            mc_bip39_entropy_from_mnemonic(mnemonic, bufferPtr, &errorPtr)
        }).mapError {
            switch $0.errorCode {
            case .invalidInput:
                return InvalidInputError(
                    "BIP39: error deriving entropy from mnemonic: \($0.description)")
            default:
                // Safety: mc_bip39_entropy_from_mnemonic should not throw non-documented errors.
                logger.fatalError(
                    "\(Self.self).\(#function): Unhandled LibMobileCoin error: \($0)")
            }
        }
    }

    /// Entropy must be a multiple of 4 bytes and 16-32 bytes in length.
    static func mnemonic(fromEntropy entropy: Data) -> Result<String, InvalidInputError> {
        guard entropy.count % 4 == 0 else {
            return .failure(InvalidInputError("BIP39 error: entropy must be a multiple of 4 bytes"))
        }
        guard entropy.count >= 16 && entropy.count <= 32 else {
            return .failure(InvalidInputError(
                "BIP39 error: entropy must be between 16 and 32 bytes, inclusive"))
        }
        return .success(entropy.asMcBuffer { entropyPtr in
            String(mcString:
                    withMcInfallibleReturningOptional { mc_bip39_entropy_to_mnemonic(entropyPtr) })
        })
    }

    static func seed(fromMnemonic mnemonic: String, passphrase: String = "")
        -> Result<Data, InvalidInputError>
    {
        Data.make(withFixedLengthMcMutableBuffer: 64) { bufferPtr, errorPtr in
            mc_bip39_get_seed(mnemonic, passphrase, bufferPtr, &errorPtr)
        }.mapError {
            switch $0.errorCode {
            case .invalidInput:
                return InvalidInputError(
                    "BIP39: error getting seed from mnemonic and passphrase: \($0.description)")
            default:
                // Safety: mc_bip39_get_seed should not throw non-documented errors.
                logger.fatalError(
                    "\(Self.self).\(#function): Unhandled LibMobileCoin error: \($0)")
            }
        }
    }

    static func words(matchingPrefix prefix: String) -> [String] {
        let wordsList =
            String(mcString: withMcInfallibleReturningOptional { mc_bip39_words_by_prefix(prefix) })
        return wordsList.split(separator: ",").map { String($0) }
    }
}
