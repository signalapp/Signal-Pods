//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public struct PaymentRequest {
    public let publicAddress: PublicAddress
    public let value: UInt64?
    public let memo: String?
    public let tokenID: UInt64
    public let paymentID: UInt64

    /// # Notes:
    /// * Providing a `value` of `0` is the same as passing `nil`, meaning no value is specified.
    /// * Providing an empty string for `memo` is the same as passing `nil`, meaning no memo is
    ///     specified.
    public init(
        publicAddress: PublicAddress,
        value: UInt64? = nil,
        memo: String? = nil,
        tokenID: UInt64 = 0,
        paymentID: UInt64 = 0
    ) {
        self.publicAddress = publicAddress

        if let value = value, value != 0 {
            self.value = value
        } else {
            self.value = nil
        }

        if let memo = memo, !memo.isEmpty {
            self.memo = memo
        } else {
            self.memo = nil
        }

        self.tokenID = tokenID
        self.paymentID = paymentID
    }
}

extension PaymentRequest: Equatable {}
extension PaymentRequest: Hashable {}

extension PaymentRequest {
    init?(_ paymentRequest: Printable_PaymentRequest) {
        guard let publicAddress = PublicAddress(paymentRequest.publicAddress) else {
            return nil
        }
        self.publicAddress = publicAddress
        self.value = paymentRequest.value != 0 ? paymentRequest.value : nil
        self.memo = !paymentRequest.memo.isEmpty ? paymentRequest.memo : nil
        self.tokenID = paymentRequest.tokenID
        self.paymentID = paymentRequest.paymentID
    }
}

extension Printable_PaymentRequest {
    init(_ paymentRequest: PaymentRequest) {
        self.init()
        self.publicAddress = External_PublicAddress(paymentRequest.publicAddress)
        if let value = paymentRequest.value {
            self.value = value
        }
        if let memo = paymentRequest.memo {
            self.memo = memo
        }
        self.tokenID = paymentRequest.tokenID
        self.paymentID = paymentRequest.paymentID
    }
}
