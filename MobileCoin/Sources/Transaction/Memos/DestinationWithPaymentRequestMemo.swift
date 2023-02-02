//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable type_name

import Foundation

public struct DestinationWithPaymentRequestMemo {
    public var memoData: Data { memoData64.data }
    public var addressHashHex: String { addressHash.hex }
    public var numberOfRecipients: UInt8 { numRecipients.value }

    let memoData64: Data64
    let addressHash: AddressHash
    let numRecipients: PositiveUInt8
    public let fee: UInt64
    public let totalOutlay: UInt64
    public let paymentRequestId: UInt64
}

extension DestinationWithPaymentRequestMemo: Equatable, Hashable { }

extension DestinationWithPaymentRequestMemo: Encodable {
    enum CodingKeys: String, CodingKey {
        case typeBytes
        case typeName
        case data
    }

    enum DataCodingKeys: String, CodingKey {
        case addressHashHex
        case numberOfRecipients
        case fee
        case totalOutlay
        case paymentRequestId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.type, forKey: .typeBytes)
        try container.encode(Self.typeName, forKey: .typeName)

        var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        try data.encode(addressHashHex, forKey: .addressHashHex)
        try data.encode(String(numberOfRecipients), forKey: .numberOfRecipients)
        try data.encode(String(fee), forKey: .fee)
        try data.encode(String(totalOutlay), forKey: .totalOutlay)
        try data.encode(String(paymentRequestId), forKey: .paymentRequestId)
    }
}

struct RecoverableDestinationWithPaymentRequestMemo {
    let memoData: Data64
    let addressHash: AddressHash
    let txOutPublicKey: RistrettoPublic
    let txOutTargetKey: RistrettoPublic
    private let accountKey: AccountKey

    init(_ memoData: Data64, accountKey: AccountKey, txOutKeys: TxOut.Keys) {
        self.memoData = memoData
        self.addressHash = DestinationWithPaymentRequestMemoUtils.getAddressHash(memoData: memoData)
        self.accountKey = accountKey
        self.txOutPublicKey = txOutKeys.publicKey
        self.txOutTargetKey = txOutKeys.targetKey
    }

    func recover() -> DestinationWithPaymentRequestMemo? {
        guard
            DestinationWithPaymentRequestMemoUtils.isValid(
                txOutPublicKey: txOutPublicKey,
                txOutTargetKey: txOutTargetKey,
                accountKey: accountKey),
            let numberOfRecipients = DestinationWithPaymentRequestMemoUtils.getNumberOfRecipients(
                memoData: memoData),
            let fee = DestinationWithPaymentRequestMemoUtils.getFee(memoData: memoData),
            let totalOutlay = DestinationWithPaymentRequestMemoUtils.getTotalOutlay(
                memoData: memoData),
            let paymentRequestId = DestinationWithPaymentRequestMemoUtils.getPaymentRequestId(
                memoData: memoData)
        else {
            logger.debug("Memo did not validate")
            return nil
        }
        let addressHash = DestinationWithPaymentRequestMemoUtils.getAddressHash(memoData: memoData)
        return DestinationWithPaymentRequestMemo(
            memoData64: memoData,
            addressHash: addressHash,
            numRecipients: numberOfRecipients,
            fee: fee,
            totalOutlay: totalOutlay,
            paymentRequestId: paymentRequestId)
    }
}

extension RecoverableDestinationWithPaymentRequestMemo: Hashable { }

extension RecoverableDestinationWithPaymentRequestMemo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.memoData == rhs.memoData
    }
}
