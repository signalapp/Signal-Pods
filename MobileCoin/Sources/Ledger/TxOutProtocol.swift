//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

protocol TxOutProtocol {
    var commitment: Data32 { get } 
    var maskedValue: UInt64 { get }
    var targetKey: RistrettoPublic { get }
    var publicKey: RistrettoPublic { get }
}

extension TxOutProtocol {
    func matches(accountKey: AccountKey) -> Bool {
        TxOutUtils.matchesSubaddress(
            targetKey: targetKey,
            publicKey: publicKey,
            viewPrivateKey: accountKey.viewPrivateKey,
            subaddressSpendPrivateKey: accountKey.subaddressSpendPrivateKey)
    }

    func matchesAnySubaddress(accountKey: AccountKey) -> Bool {
        TxOutUtils.matchesAnySubaddress(
            maskedValue: maskedValue,
            publicKey: publicKey,
            viewPrivateKey: accountKey.viewPrivateKey)
    }

    func subaddressSpentPublicKey(viewPrivateKey: RistrettoPrivate) -> RistrettoPublic {
        TxOutUtils.subaddressSpentPublicKey(
            targetKey: targetKey,
            publicKey: publicKey,
            viewPrivateKey: viewPrivateKey)
    }

    /// - Returns: `nil` when `accountKey` cannot unmask value, either because `accountKey` does not
    ///     own `TxOut` or because ` TxOut` values are incongruent.
    func value(accountKey: AccountKey) -> UInt64? {
        TxOutUtils.value(
            maskedValue: maskedValue,
            publicKey: publicKey,
            viewPrivateKey: accountKey.viewPrivateKey)
    }

    typealias IndexedKeyImage = (index: UInt64, keyImage: KeyImage)
    
    /// - Returns: `nil` when a valid `KeyImage` cannot be constructed, either because `accountKey`
    ///     does not own `TxOut` or because `TxOut` values are incongruent.
    func keyImage(accountKey: AccountKey) -> IndexedKeyImage? {
        [indexedKeyImage(index: accountKey.subaddressIndex, accountKey: accountKey),
         indexedKeyImage(index: accountKey.changeSubaddressIndex, accountKey: accountKey)]
        .compactMap({$0})
        .first
    }
    
    private func indexedKeyImage(index: UInt64, accountKey: AccountKey) -> IndexedKeyImage? {
        guard
            let sspk = accountKey.subaddressSpendPrivateKey(index: index),
            let keyImage = TxOutUtils.keyImage(
                                        targetKey: targetKey,
                                        publicKey: publicKey,
                                        viewPrivateKey: accountKey.viewPrivateKey,
                                        subaddressSpendPrivateKey: sspk)
        else {
            return nil
        }
        return (index: index, keyImage: keyImage)
    }
}

extension FogView_TxOutRecord {
    init(_ txOut: TxOutProtocol) {
        self.init()
        self.txOutAmountCommitmentData = txOut.commitment.data
        self.txOutAmountMaskedValue = txOut.maskedValue
        self.txOutTargetKeyData = txOut.targetKey.data
        self.txOutPublicKeyData = txOut.publicKey.data
    }
}
