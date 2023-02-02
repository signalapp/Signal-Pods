//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct SenderWithPaymentRequestMemo {
    public var memoData: Data { memoData64.data }
    public var addressHashHex: String { addressHash.hex }

    let memoData64: Data64
    let addressHash: AddressHash
    public let paymentRequestId: UInt64
}

extension SenderWithPaymentRequestMemo: Equatable, Hashable { }

extension SenderWithPaymentRequestMemo: Encodable {
    enum CodingKeys: String, CodingKey {
        case typeBytes
        case typeName
        case data
    }

    enum DataCodingKeys: String, CodingKey {
        case addressHashHex
        case paymentRequestId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.type, forKey: .typeBytes)
        try container.encode(Self.typeName, forKey: .typeName)

        var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        try data.encode(addressHashHex, forKey: .addressHashHex)
        try data.encode(String(paymentRequestId), forKey: .paymentRequestId)
    }
}

struct RecoverableSenderWithPaymentRequestMemo {
    let memoData: Data64
    let addressHash: AddressHash
    let txOutPublicKey: RistrettoPublic
    private let accountKey: AccountKey

    init(_ memoData: Data64, accountKey: AccountKey, txOutPublicKey: RistrettoPublic) {
        self.memoData = memoData
        self.addressHash = SenderWithPaymentRequestMemoUtils.getAddressHash(memoData: memoData)
        self.accountKey = accountKey
        self.txOutPublicKey = txOutPublicKey
    }

    func recover(senderPublicAddress: PublicAddress) -> SenderWithPaymentRequestMemo? {
        guard SenderWithPaymentRequestMemoUtils.isValid(
            memoData: memoData,
            senderPublicAddress: senderPublicAddress,
            receipientViewPrivateKey: accountKey.subaddressViewPrivateKey,
            txOutPublicKey: txOutPublicKey)
        else {
            logger.debug("Memo did not validate")
            return nil
        }

        let paymentReqId = SenderWithPaymentRequestMemoUtils.getPaymentRequestId(memoData: memoData)
        guard let paymentRequestId = paymentReqId else {
            logger.debug("Unable to get payment request id")
            return nil
        }

        let addressHash = SenderWithPaymentRequestMemoUtils.getAddressHash(memoData: memoData)
        return SenderWithPaymentRequestMemo(
            memoData64: memoData,
            addressHash: addressHash,
            paymentRequestId: paymentRequestId)
    }

    func unauthenticatedMemo() -> SenderWithPaymentRequestMemo? {
        let paymentReqId = SenderWithPaymentRequestMemoUtils.getPaymentRequestId(memoData: memoData)
        guard let paymentRequestId = paymentReqId else {
            logger.debug("Unable to get payment request id")
            return nil
        }

        let addressHash = SenderWithPaymentRequestMemoUtils.getAddressHash(memoData: memoData)
        return SenderWithPaymentRequestMemo(
            memoData64: memoData,
            addressHash: addressHash,
            paymentRequestId: paymentRequestId)
    }
}

extension RecoverableSenderWithPaymentRequestMemo: Hashable { }

extension RecoverableSenderWithPaymentRequestMemo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.memoData == rhs.memoData
    }
}
