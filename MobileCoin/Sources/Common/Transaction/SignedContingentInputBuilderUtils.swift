//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//
// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum SignedContingentInputBuilderUtils {

    static func addRequiredOutput(
        ptr: OpaquePointer,
        publicAddress: PublicAddress,
        amount: Amount,
        rng: MobileCoinRng
    ) -> Result<TxOut, TransactionBuilderError> {
        var confirmationNumberData = Data32()

        func ffiInner(
            publicAddressPtr: UnsafePointer<McPublicAddress>,
            rngCallbackPtr: UnsafeMutablePointer<McRngCallback>?
        ) -> Result<Data, TransactionBuilderError> {
            confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in
                Data.make(withMcDataBytes: { errorPtr in
                    mc_signed_contingent_input_builder_add_required_output(
                        ptr,
                        amount.value,
                        amount.tokenId.value,
                        publicAddressPtr,
                        rngCallbackPtr,
                        confirmationNumberPtr,
                        &errorPtr)
                }).mapError {
                    switch $0.errorCode {
                    case .invalidInput:
                        return .invalidInput("\(redacting: $0.description)")
                    default:
                        // Safety: mc_signed_contingent_input_builder_add_required_output should not
                        // throw non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }
            }
        }

        return publicAddress.withUnsafeCStructPointer { publicAddressPtr in
            withMcRngObjCallback(rng: rng) { rngCallbackPtr in
                // Using an in-line func for the FFI Inner to keep closure size low.
                ffiInner(publicAddressPtr: publicAddressPtr, rngCallbackPtr: rngCallbackPtr)
            }
        }.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_signed_contingent_input_builder_add_required_output should always
                // return valid data on success.
                logger.fatalError("mc_signed_contingent_input_builder_add_required_output " +
                    "returned invalid data: \(redacting: txOutData.base64EncodedString())")
            }

            return txOut
        }
    }

    static func addRequiredChangeOutput(
        ptr: OpaquePointer,
        accountKey: AccountKey,
        amount: Amount,
        rng: MobileCoinRng
    ) -> Result<TxOut, TransactionBuilderError> {
        var confirmationNumberData = Data32()

        let result: Result<Data, TransactionBuilderError> = McAccountKey.withUnsafePointer(
            viewPrivateKey: accountKey.viewPrivateKey,
            spendPrivateKey: accountKey.spendPrivateKey,
            fogInfo: accountKey.fogInfo
        ) { accountKeyPtr in
            withMcRngObjCallback(rng: rng) { rngCallbackPtr in
                confirmationNumberData.asMcMutableBuffer { confirmationNumberPtr in

                    Data.make(withMcDataBytes: { errorPtr in
                        mc_signed_contingent_input_builder_add_required_change_output(
                            accountKeyPtr,
                            ptr,
                            amount.value,
                            amount.tokenId.value,
                            rngCallbackPtr,
                            confirmationNumberPtr,
                            &errorPtr)
                    }).mapError {
                        switch $0.errorCode {
                        case .invalidInput:
                            return .invalidInput("\(redacting: $0.description)")
                        default:
                            // Safety: mc_signed_contingent_input_builder_add_required_change_output
                            // should not throw non-documented errors.
                            logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                        }
                    }
                }
            }
        }

        return result.map { txOutData in
            guard let txOut = TxOut(serializedData: txOutData) else {
                // Safety: mc_signed_contingent_input_builder_add_required_change_output should
                // always return valid data on success.
                logger.fatalError("mc_signed_contingent_input_builder_add_required_change_output " +
                    "returned invalid data: \(redacting: txOutData.base64EncodedString())")
            }

            return txOut
        }
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
        rng: MobileCoinRng,
        ring: McTransactionBuilderRing
    ) -> Result<SignedContingentInput, TransactionBuilderError> {

        withMcRngObjCallback(rng: rng) { rngCallbackPtr in
            ring.withUnsafeOpaquePointer { ringPtr in
                Data.make(withMcDataBytes: { errorPtr in
                    mc_signed_contingent_input_builder_build(
                        ptr,
                        rngCallbackPtr,
                        ringPtr,
                        &errorPtr)
                }).mapError {
                    switch $0.errorCode {
                    case .invalidInput:
                        return .invalidInput("\(redacting: $0.description)")
                    default:
                        // Safety: mc_signed_contingent_input_builder_build should not throw
                        // non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }
            }
        }.map { sciBytes in
            guard let sci = SignedContingentInput(serializedData: sciBytes) else {
                // Safety: mc_signed_contingent_input_builder_build should always return valid data
                // on success.
                logger.fatalError("mc_signed_contingent_input_builder_build returned invalid " +
                    "data: \(redacting: sciBytes.base64EncodedString())")
            }
            return sci
        }
    }

    static func signed_contingent_input_is_valid(sciData: Data) -> Bool {
        func ffiCall(
            sciDataPtr: UnsafePointer<McBuffer>
        ) -> Bool {
            let result = withMcError { errorPtr in
                mc_signed_contingent_input_data_is_valid(
                    sciDataPtr,
                    &errorPtr)
            }
            switch result {
            case .success:
                return true
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to the above FFI func are supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return false
                default:
                    // Safety: mc_memo_sender_with_payment_request_memo_is_valid
                    // should not throw non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return false
                }
            }
        }

        return sciData.asMcBuffer { sciDataPtr in
            ffiCall(sciDataPtr: sciDataPtr)
        }
    }

}
