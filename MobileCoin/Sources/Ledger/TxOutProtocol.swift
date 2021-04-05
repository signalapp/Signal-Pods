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
            commitment: commitment,
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
            commitment: commitment,
            maskedValue: maskedValue,
            publicKey: publicKey,
            viewPrivateKey: accountKey.viewPrivateKey)
    }

    /// - Returns: `nil` when a valid `KeyImage` cannot be constructed, either because `accountKey`
    ///     does not own `TxOut` or because `TxOut` values are incongruent.
    func keyImage(accountKey: AccountKey) -> KeyImage? {
        TxOutUtils.keyImage(
            targetKey: targetKey,
            publicKey: publicKey,
            viewPrivateKey: accountKey.viewPrivateKey,
            subaddressSpendPrivateKey: accountKey.subaddressSpendPrivateKey)
    }
}

extension FogView_FogTxOut {
    init(_ txOut: TxOutProtocol) {
        self.init()
        self.amount =
            External_Amount(commitment: txOut.commitment, maskedValue: txOut.maskedValue)
        self.targetKey = External_CompressedRistretto(txOut.targetKey)
        self.publicKey = External_CompressedRistretto(txOut.publicKey)
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
