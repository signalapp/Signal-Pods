//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct OwnedTxOut {
    let publicKeyTyped: RistrettoPublic
    /// - Returns: `TxOut` public key
    public var publicKey: Data { publicKeyTyped.data }

    public let value: UInt64

    public let tokenId: TokenId

    let keyImageTyped: KeyImage
    /// - Returns: `TxOut` key  image
    public var keyImage: Data { keyImageTyped.data }

    public let receivedBlock: BlockMetadata

    public let spentBlock: BlockMetadata?

    public let subaddressIndex: UInt64

    public let sharedSecret: Data

    let recoverableMemo: RecoverableMemo

    init(
        _ knownTxOut: KnownTxOut,
        receivedBlock: BlockMetadata,
        spentBlock: BlockMetadata?
    ) {
        self.publicKeyTyped = knownTxOut.publicKey
        self.value = knownTxOut.value
        self.tokenId = knownTxOut.tokenId
        self.keyImageTyped = knownTxOut.keyImage
        self.receivedBlock = receivedBlock
        self.spentBlock = spentBlock
        self.subaddressIndex = knownTxOut.subaddressIndex
        self.sharedSecret = knownTxOut.sharedSecret.data
        self.recoverableMemo = knownTxOut.recoverableMemo
    }
}

extension OwnedTxOut: Equatable {}
extension OwnedTxOut: Hashable {}
