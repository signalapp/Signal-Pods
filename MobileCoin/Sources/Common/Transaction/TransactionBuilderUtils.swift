//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum TransactionBuilderUtils {
    static func addInput(
        ptr: OpaquePointer,
        preparedTxInput: PreparedTxInput,
        viewPrivateKey: RistrettoPrivate,
        subaddressSpendPrivateKey: RistrettoPrivate
    ) -> Result<(), TransactionBuilderError> {
        let ring = McTransactionBuilderRing(ring: preparedTxInput.ring)
        return viewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            subaddressSpendPrivateKey.asMcBuffer { subaddressSpendPrivateKeyPtr in
                ring.withUnsafeOpaquePointer { ringPtr in
                    withMcError { errorPtr in
                        mc_transaction_builder_add_input(
                            ptr,
                            viewPrivateKeyPtr,
                            subaddressSpendPrivateKeyPtr,
                            preparedTxInput.realInputIndex,
                            ringPtr,
                            &errorPtr)
                    }.mapError {
                        switch $0.errorCode {
                        case .invalidInput:
                            return .invalidInput("\(redacting: $0.description)")
                        default:
                            // Safety: mc_transaction_builder_add_input should not throw
                            // non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                        }
                    }
                }
            }
        }
    }

    static func addSignedContingentInput(
        ptr: OpaquePointer,
        signedContingentInput: SignedContingentInput
    ) -> Result<(), TransactionBuilderError> {
        let sciData = signedContingentInput.serializedData
        return sciData.asMcBuffer { sciDataPtr in
            withMcError { errorPtr in
                mc_transaction_builder_add_presigned_input(
                    ptr,
                    sciDataPtr,
                    &errorPtr)
            }.mapError {
                switch $0.errorCode {
                case .invalidInput:
                    return .invalidInput("\(redacting: $0.description)")
                default:
                    // Safety: mc_transaction_builder_add_presigned_input should not throw
                    // non-documented errors.
                    logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                }
            }
        }
    }

    static func addOutput(
        ptr: OpaquePointer,
        tombstoneBlockIndex: UInt64,
        publicAddress: PublicAddress,
        amount: Amount,
        rng: MobileCoinRng
    ) -> Result<TxOutContext, TransactionBuilderError> {

        func ffiInner(
            publicAddressPtr: UnsafePointer<McPublicAddress>,
            rngCallbackPtr: UnsafeMutablePointer<McRngCallback>?
        ) -> Result<Data, TransactionBuilderError> {
            confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in
                sharedSecretData.asMcMutableBuffer { sharedSecretPtr in
                    Data.make(withMcDataBytes: { errorPtr in
                        mc_transaction_builder_add_output_mixed(
                            ptr,
                            amount.value,
                            amount.tokenId.value,
                            publicAddressPtr,
                            rngCallbackPtr,
                            confirmationNumberPtr,
                            sharedSecretPtr,
                            &errorPtr)
                    }).mapError {
                        switch $0.errorCode {
                        case .invalidInput:
                            return .invalidInput("\(redacting: $0.description)")
                        case .attestationVerificationFailed:
                            return .attestationVerificationFailed("\(redacting: $0.description)")
                        default:
                            // Safety: mc_transaction_builder_add_output should not throw
                            // non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                        }
                    }
                }
            }
        }

        var confirmationNumberData = Data32()
        var sharedSecretData = Data32()
        return publicAddress.withUnsafeCStructPointer { publicAddressPtr in
            withMcRngObjCallback(rng: rng) { rngCallbackPtr in
                // Using an in-line func for the FFI Inner to keep closure size low.
                ffiInner(publicAddressPtr: publicAddressPtr, rngCallbackPtr: rngCallbackPtr)
            }
        }.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_transaction_builder_add_output should always return valid data on
                // success.
                logger.fatalError("mc_transaction_builder_add_output returned invalid data: " +
                    "\(redacting: txOutData.base64EncodedString())")
            }

            let confirmationNumber = TxOutConfirmationNumber(confirmationNumberData)
            let sharedSecret = RistrettoPublic(skippingValidation: sharedSecretData)
            let receipt = Receipt(
                txOut: txOut,
                confirmationNumber: confirmationNumber,
                tombstoneBlockIndex: tombstoneBlockIndex)
            return TxOutContext(txOut, receipt, sharedSecret)
        }
    }

    // swiftlint:disable closure_body_length
    static func addChangeOutput(
        ptr: OpaquePointer,
        tombstoneBlockIndex: UInt64,
        accountKey: AccountKey,
        amount: Amount,
        rng: MobileCoinRng
    ) -> Result<TxOutContext, TransactionBuilderError> {
        var confirmationNumberData = Data32()
        var sharedSecretData = Data32()

        let result: Result<Data, TransactionBuilderError> = McAccountKey.withUnsafePointer(
            viewPrivateKey: accountKey.viewPrivateKey,
            spendPrivateKey: accountKey.spendPrivateKey,
            fogInfo: accountKey.fogInfo
        ) { accountKeyPtr in
            withMcRngObjCallback(rng: rng) { rngCallbackPtr in
                confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in
                    sharedSecretData.asMcMutableBuffer { sharedSecretPtr in
                        Data.make(withMcDataBytes: { errorPtr in
                            mc_transaction_builder_add_change_output_mixed(
                                accountKeyPtr,
                                ptr,
                                amount.value,
                                amount.tokenId.value,
                                rngCallbackPtr,
                                confirmationNumberPtr,
                                sharedSecretPtr,
                                &errorPtr)
                        }).mapError {
                            switch $0.errorCode {
                            case .invalidInput:
                                return .invalidInput("\(redacting: $0.description)")
                            case .attestationVerificationFailed:
                                return .attestationVerificationFailed(
                                    "\(redacting: $0.description)")
                            default:
                                // Safety: mc_transaction_builder_add_output should not throw
                                // non-documented errors.
                                logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                            }
                        }
                    }
                }
            }
        }

        return renderTxOutContext(
            confirmationNumberData: confirmationNumberData,
            sharedSecretData: sharedSecretData,
            tombstoneBlockIndex: tombstoneBlockIndex,
            result: result)
    }
    // swiftlint:enable closure_body_length
    private static func renderTxOutContext(
        confirmationNumberData: Data32,
        sharedSecretData: Data32,
        tombstoneBlockIndex: UInt64,
        result: Result<Data, TransactionBuilderError>
    ) -> Result<TxOutContext, TransactionBuilderError> {
        result.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_transaction_builder_add_output should always return valid data on
                // success.
                logger.fatalError("mc_transaction_builder_add_output returned invalid data: " +
                    "\(redacting: txOutData.base64EncodedString())")
            }

            let confirmationNumber = TxOutConfirmationNumber(confirmationNumberData)
            let sharedSecret = RistrettoPublic(skippingValidation: sharedSecretData)
            let receipt = Receipt(
                txOut: txOut,
                confirmationNumber: confirmationNumber,
                tombstoneBlockIndex: tombstoneBlockIndex)
            return TxOutContext(txOut, receipt, sharedSecret)
        }
    }

    static func build(
        ptr: OpaquePointer,
        rng: MobileCoinRng
    ) -> Result<Transaction, TransactionBuilderError> {

        withMcRngObjCallback(rng: rng) { rngCallbackPtr in
            Data.make(withMcDataBytes: { errorPtr in
                mc_transaction_builder_build(ptr, rngCallbackPtr, &errorPtr)
            }).mapError {
                switch $0.errorCode {
                case .invalidInput:
                    return .invalidInput("\(redacting: $0.description)")
                default:
                    // Safety: mc_transaction_builder_build should not throw non-documented errors.
                    logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                }
            }
        }.map { txBytes in
            guard let transaction = Transaction(serializedData: txBytes) else {
                // Safety: mc_transaction_builder_build should always return valid data on success.
                logger.fatalError("mc_transaction_builder_build returned invalid data: " +
                    "\(redacting: txBytes.base64EncodedString())")
            }
            return transaction
        }
    }
}
