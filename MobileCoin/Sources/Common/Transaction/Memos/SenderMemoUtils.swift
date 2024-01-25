//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable closure_body_length

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum SenderMemoUtils {
    static func isValid(
        memoData: Data64,
        senderPublicAddress: PublicAddress,
        receipientViewPrivateKey: RistrettoPrivate,
        txOutPublicKey: RistrettoPublic
    ) -> Bool {
        memoData.asMcBuffer { memoDataPtr in
            senderPublicAddress.withUnsafeCStructPointer { publicAddressPtr in
                receipientViewPrivateKey.asMcBuffer { receipientViewPrivateKeyPtr in
                    txOutPublicKey.asMcBuffer { txOutPublicKeyPtr in
                        var matches = false
                        let result = withMcError { errorPtr in
                            mc_memo_sender_memo_is_valid(
                                memoDataPtr,
                                publicAddressPtr,
                                receipientViewPrivateKeyPtr,
                                txOutPublicKeyPtr,
                                &matches,
                                &errorPtr)
                        }
                        switch result {
                        case .success:
                            return matches
                        case .failure(let error):
                            switch error.errorCode {
                            case .invalidInput:
                                // Safety: This condition indicates a programming error and can only
                                // happen if arguments to mc_memo_sender_memo_is_valid are
                                // supplied incorrectly.
                                logger.warning("error: \(redacting: error)")
                                return false
                            default:
                                // Safety: mc_memo_sender_memo_is_valid should not throw
                                // non-documented errors.
                                logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                                return false
                            }
                        }
                    }
                }
            }
        }
    }

    static func getAddressHash(
        memoData: Data64
    ) -> AddressHash {
        let bytes: Data16 = memoData.asMcBuffer { memoDataPtr in
            switch Data16.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                mc_memo_sender_memo_get_address_hash(
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
                    // happen if arguments to mc_memo_sender_memo_get_address_hash are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return Data16()
                default:
                    // Safety: mc_memo_sender_memo_get_address_hash should not throw
                    // non-documented errors.
                    logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                    return Data16()
                }
            }
        }
        return AddressHash(bytes)
    }

    static func create(
        senderAccountKey: AccountKey,
        receipientPublicAddress: PublicAddress,
        txOutPublicKey: RistrettoPublic
    ) -> Data64? {
        senderAccountKey.withUnsafeCStructPointer { senderAccountKeyPtr in
            receipientPublicAddress.viewPublicKeyTyped.asMcBuffer { viewPublicKeyPtr in
                txOutPublicKey.asMcBuffer { txOutPublicKeyPtr in
                    switch Data64.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                        mc_memo_sender_memo_create(
                            senderAccountKeyPtr,
                            viewPublicKeyPtr,
                            txOutPublicKeyPtr,
                            bufferPtr,
                            &errorPtr)
                    }) {
                    case .success(let bytes):
                        return bytes as Data64
                    case .failure(let error):
                        switch error.errorCode {
                        case .invalidInput:
                            // Safety: This condition indicates a programming error and can only
                            // happen if arguments to mc_memo_sender_memo_create are
                            // supplied incorrectly.
                            logger.warning("error: \(redacting: error)")
                            return nil
                        default:
                            // Safety: mc_memo_sender_memo_create should not throw
                            // non-documented errors.
                            logger.warning("Unhandled LibMobileCoin error: \(redacting: error)")
                            return nil
                        }
                    }
                }
            }
        }
    }
}
