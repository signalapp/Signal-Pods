//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains operator_usage_whitespace

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

/// See https://github.com/satoshilabs/slips/blob/master/slip-0010.md
enum Slip10Utils {
    static func accountPrivateKeys(fromMnemonic mnemonic: Mnemonic, accountIndex: UInt32)
        -> (viewPrivateKey: RistrettoPrivate, spendPrivateKey: RistrettoPrivate)
    {
        var viewPrivateKeyOut = Data32()
        var spendPrivateKeyOut = Data32()
        viewPrivateKeyOut.asMcMutableBuffer { viewPrivateKeyOutPtr in
            spendPrivateKeyOut.asMcMutableBuffer { spendPrivateKeyOutPtr in
                switch withMcError({ errorPtr in
                    mc_slip10_account_private_keys_from_mnemonic(
                        mnemonic.phrase,
                        accountIndex,
                        viewPrivateKeyOutPtr,
                        spendPrivateKeyOutPtr,
                        &errorPtr)
                }) {
                case .success:
                    break
                case .failure(let error):
                    switch error.errorCode {
                    case .invalidInput:
                        // Safety: mnemonic is guaranteed to satisfy
                        // mc_slip10_account_private_keys_from_mnemonic preconditions.
                        logger.fatalError(
                            "LibMobileCoin invalidInput error: \(redacting: error.description)")
                    default:
                        // Safety: mc_slip10_account_private_keys_from_mnemonic should not throw
                        // non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: error)")
                    }
                }
            }
        }
        // Safety: It's safe to skip validation because
        // mc_slip10_account_private_keys_from_mnemonic should always return valid
        // RistrettoPrivate values on success.
        return (RistrettoPrivate(skippingValidation: viewPrivateKeyOut),
                RistrettoPrivate(skippingValidation: spendPrivateKeyOut))
    }

    static func accountPrivateKeys(fromMnemonic mnemonic: String, accountIndex: UInt32)
        -> Result<(viewPrivateKey: RistrettoPrivate, spendPrivateKey: RistrettoPrivate),
                  InvalidInputError>
    {
        var viewPrivateKeyOut = Data32()
        var spendPrivateKeyOut = Data32()
        return viewPrivateKeyOut.asMcMutableBuffer { viewPrivateKeyOutPtr in
            spendPrivateKeyOut.asMcMutableBuffer { spendPrivateKeyOutPtr in
                withMcError { errorPtr in
                    mc_slip10_account_private_keys_from_mnemonic(
                        mnemonic,
                        accountIndex,
                        viewPrivateKeyOutPtr,
                        spendPrivateKeyOutPtr,
                        &errorPtr)
                }.mapError {
                    switch $0.errorCode {
                    case .invalidInput:
                        return InvalidInputError("\(redacting: $0.description)")
                    default:
                        // Safety: mc_slip10_account_private_keys_from_mnemonic should not throw
                        // non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }
            }
        }.map {
            // Safety: It's safe to skip validation because
            // mc_slip10_account_private_keys_from_mnemonic should always return valid
            // RistrettoPrivate values on success.
            return (RistrettoPrivate(skippingValidation: viewPrivateKeyOut),
                    RistrettoPrivate(skippingValidation: spendPrivateKeyOut))
        }
    }
}
