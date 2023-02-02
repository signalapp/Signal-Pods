//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct SenderMemo {
    public var memoData: Data { memoData64.data }
    public var addressHashHex: String { addressHash.hex }

    let memoData64: Data64
    let addressHash: AddressHash
}

extension SenderMemo: Equatable, Hashable { }

extension SenderMemo: Encodable {
    enum CodingKeys: String, CodingKey {
        case typeBytes
        case typeName
        case data
    }

    enum DataCodingKeys: String, CodingKey {
        case addressHashHex
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.type, forKey: .typeBytes)
        try container.encode(Self.typeName, forKey: .typeName)

        var data = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        try data.encode(addressHashHex, forKey: .addressHashHex)
    }
}

struct RecoverableSenderMemo {
    let memoData: Data64
    let addressHash: AddressHash
    let txOutPublicKey: RistrettoPublic
    private let accountKey: AccountKey

    init(_ memoData: Data64, accountKey: AccountKey, txOutPublicKey: RistrettoPublic) {
        self.memoData = memoData
        self.addressHash = SenderMemoUtils.getAddressHash(memoData: memoData)
        self.accountKey = accountKey
        self.txOutPublicKey = txOutPublicKey
    }

    func recover(senderPublicAddress: PublicAddress) -> SenderMemo? {
        guard SenderMemoUtils.isValid(
            memoData: memoData,
            senderPublicAddress: senderPublicAddress,
            receipientViewPrivateKey: accountKey.subaddressViewPrivateKey,
            txOutPublicKey: txOutPublicKey)
        else {
            return nil
        }
        return SenderMemo(memoData64: memoData, addressHash: addressHash)
    }

    func unauthenticatedMemo() -> SenderMemo? {
        SenderMemo(memoData64: memoData, addressHash: addressHash)
    }

}

extension RecoverableSenderMemo: Hashable { }

extension RecoverableSenderMemo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.memoData == rhs.memoData
    }
}
