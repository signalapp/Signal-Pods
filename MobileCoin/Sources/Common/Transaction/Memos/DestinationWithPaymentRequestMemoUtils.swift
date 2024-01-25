//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum DestinationWithPaymentRequestMemoUtils {

    static func isValid(
        txOutPublicKey: RistrettoPublic,
        txOutTargetKey: RistrettoPublic,
        accountKey: AccountKey
    ) -> Bool {
        TxOutUtils.matchesSubaddress(
             targetKey: txOutTargetKey,
             publicKey: txOutPublicKey,
             viewPrivateKey: accountKey.viewPrivateKey,
             subaddressSpendPrivateKey: accountKey.changeSubaddressSpendPrivateKey)
    }

    static func getAddressHash(
        memoData: Data64
    ) -> AddressHash {
        let bytes: Data16 = memoData.asMcBuffer { memoDataPtr in
            switch Data16.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                mc_memo_destination_with_payment_request_memo_get_address_hash(
                    memoDataPtr,
                    bufferPtr,
                    &errorPtr)
            }) {
            case .success(let bytes):
                return bytes as Data16
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to
                    // mc_memo_destination_with_payment_request_memo_get_address_hash are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return Data16()
                default:
                    // Safety:
                    // mc_memo_destination_with_payment_request_memo_get_address_hash
                    // should not throw non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return Data16()
                }
            }
        }
        return AddressHash(bytes)
    }

    static func create(
        destinationPublicAddress: PublicAddress,
        numberOfRecipients: PositiveUInt8,
        fee: UInt64,
        totalOutlay: UInt64
    ) -> Data64? {
        destinationPublicAddress.withUnsafeCStructPointer { destinationPublicAddressPtr in
            switch Data64.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                mc_memo_destination_with_payment_request_memo_create(
                    destinationPublicAddressPtr,
                    numberOfRecipients.value,
                    fee,
                    totalOutlay,
                    bufferPtr,
                    &errorPtr)
            }) {
            case .success(let bytes):
                return bytes as Data64
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to
                    // mc_memo_destination_with_payment_request_memo_create
                    // are supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return nil
                default:
                    // Safety: mc_memo_destination_with_payment_request_memo_create should not throw
                    // non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return nil
                }
            }
        }
    }

    static func getFee(
        memoData: Data64
    ) -> UInt64? {
        memoData.asMcBuffer { memoDataPtr in
            var out_fee: UInt64 = 0
            let result = withMcError { errorPtr in
                mc_memo_destination_with_payment_request_memo_get_fee(
                    memoDataPtr,
                    &out_fee,
                    &errorPtr)
            }
            switch result {
            case .success:
                return out_fee
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to
                    // mc_memo_destination_with_payment_request_memo_get_fee are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return nil
                default:
                    // Safety:
                    // mc_memo_destination_with_payment_request_memo_get_fee should not throw
                    // non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return nil
                }
            }
        }
    }

    static func getTotalOutlay(
        memoData: Data64
    ) -> UInt64? {
        memoData.asMcBuffer { memoDataPtr in
            var out_total_outlay: UInt64 = 0
            let result = withMcError { errorPtr in
                mc_memo_destination_with_payment_request_memo_get_total_outlay(
                    memoDataPtr,
                    &out_total_outlay,
                    &errorPtr)
            }
            switch result {
            case .success:
                return out_total_outlay
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to
                    // mc_memo_destination_with_payment_request_memo_get_total_outlay are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return nil
                default:
                    // Safety:
                    // mc_memo_destination_with_payment_request_memo_get_total_outlay
                    // should not throw non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return nil
                }
            }
        }
    }

    static func getNumberOfRecipients(
        memoData: Data64
    ) -> PositiveUInt8? {
        memoData.asMcBuffer { memoDataPtr in
            var out_number_of_recipients: UInt8 = 0
            let result = withMcError { errorPtr in
                mc_memo_destination_with_payment_request_memo_get_number_of_recipients(
                    memoDataPtr,
                    &out_number_of_recipients,
                    &errorPtr)
            }
            switch result {
            case .success:
                // Number of recipients must always be greater than 1
                return PositiveUInt8(out_number_of_recipients)
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only happen
                    // if arguments t0
                    // mc_memo_destination_with_payment_request_memo_get_number_of_recipients are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return nil
                default:
                    // Safety:
                    // mc_memo_destination_with_payment_request_memo_get_number_of_recipients
                    // should not throw non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return nil
                }
            }
        }
    }

    static func getPaymentRequestId(
        memoData: Data64
    ) -> UInt64? {
        memoData.asMcBuffer { memoDataPtr in
            var out_payment_request_id: UInt64 = 0
            let result = withMcError { errorPtr in
                mc_memo_destination_with_payment_request_memo_get_payment_request_id(
                    memoDataPtr,
                    &out_payment_request_id,
                    &errorPtr)
            }
            switch result {
            case .success:
                return out_payment_request_id
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments to
                    // mc_memo_destination_with_payment_request_memo_get_payment_request_id are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return nil
                default:
                    // Safety:
                    // mc_memo_destination_with_payment_request_memo_get_payment_request_id
                    // should not throw non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return nil
                }
            }
        }
    }

}
