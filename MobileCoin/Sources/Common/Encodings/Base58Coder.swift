//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public enum Base58DecodingResult {
    case publicAddress(PublicAddress)
    case paymentRequest(PaymentRequest)
    case transferPayload(TransferPayload)
}

public enum Base58Coder {
    public static func encode(_ publicAddress: PublicAddress) -> String {
        var wrapper = Printable_PrintableWrapper()
        wrapper.publicAddress = External_PublicAddress(publicAddress)
        return wrapper.base58EncodedString()
    }

    public static func encode(_ paymentRequest: PaymentRequest) -> String {
        var wrapper = Printable_PrintableWrapper()
        wrapper.paymentRequest = Printable_PaymentRequest(paymentRequest)
        return wrapper.base58EncodedString()
    }

    public static func encode(_ transferPayload: TransferPayload) -> String {
        var wrapper = Printable_PrintableWrapper()
        wrapper.transferPayload = Printable_TransferPayload(transferPayload)
        return wrapper.base58EncodedString()
    }

    /// - Returns: `nil` when the input is not decodable.
    public static func decode(_ base58String: String) -> Base58DecodingResult? {
        guard let wrapper = Printable_PrintableWrapper(base58Encoded: base58String) else {
            return nil
        }

        switch wrapper.wrapper {
        case .publicAddress(let publicAddress):
            guard let publicAddress = PublicAddress(publicAddress) else {
                return nil
            }
            return .publicAddress(publicAddress)
        case .paymentRequest(let paymentRequest):
            guard let paymentRequest = PaymentRequest(paymentRequest) else {
                return nil
            }
            return .paymentRequest(paymentRequest)
        case .transferPayload(let transferPayload):
            guard let transferPayload = TransferPayload(transferPayload) else {
                return nil
            }
            return .transferPayload(transferPayload)
        case .txOutGiftCode:
            return nil
        case .none:
            return nil
        }
    }
}
