//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

protocol TxOutProtocol {
    var encryptedMemo: Data66 { get }
    var commitment: Data32 { get }
    var maskedAmount: MaskedAmount { get }
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

    func subaddressSpentPublicKey(viewPrivateKey: RistrettoPrivate) -> RistrettoPublic {
        TxOutUtils.subaddressSpentPublicKey(
            targetKey: targetKey,
            publicKey: publicKey,
            viewPrivateKey: viewPrivateKey)
    }

    /// - Returns: `nil` when `accountKey` cannot unmask value, either because `accountKey` does not
    ///     own `TxOut` or because ` TxOut` values are incongruent.
    func value(accountKey: AccountKey) -> UInt64? {
        amount(accountKey: accountKey)?.value
    }

    /// - Returns: `nil` when `accountKey` cannot unmask value, either because `accountKey` does not
    ///     own `TxOut` or because ` TxOut` values are incongruent.
    func tokenId(accountKey: AccountKey) -> TokenId? {
        amount(accountKey: accountKey)?.tokenId
    }

    /// - Returns: `nil` when `accountKey` cannot unmask the amoount, either because `accountKey`
    ///     does not own `TxOut` or because ` TxOut` amounts are incongruent.
    func amount(accountKey: AccountKey) -> Amount? {
        TxOutUtils.amount(
            maskedAmount: maskedAmount,
            publicKey: publicKey,
            viewPrivateKey: accountKey.viewPrivateKey)
    }

    typealias IndexedKeyImage = (index: UInt64, keyImage: KeyImage)

    /// - Returns: `nil` when a valid `KeyImage` cannot be constructed, either because `accountKey`
    ///     does not own `TxOut` or because `TxOut` values are incongruent.
    func keyImage(accountKey: AccountKey) -> IndexedKeyImage? {
        McConstants.POSSIBLE_SUBADDRESSES.compactMap {
            constructKeyImage(index: $0, accountKey: accountKey)
        }.first
    }

    func constructKeyImage(index: UInt64, accountKey: AccountKey) -> IndexedKeyImage? {
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

    var keys: TxOut.Keys {
        (publicKey: publicKey, targetKey: targetKey)
    }
}

extension FogView_TxOutRecord {
    init(_ txOut: TxOutProtocol) {
        self.init()
        self.txOutAmountCommitmentData = txOut.commitment.data
        self.txOutAmountMaskedValue = txOut.maskedAmount.maskedValue
        self.txOutTargetKeyData = txOut.targetKey.data
        self.txOutPublicKeyData = txOut.publicKey.data
        self.txOutEMemoData = txOut.encryptedMemo.data

        switch txOut.maskedAmount.version {
        case .v1:
            self.txOutAmountMaskedV1TokenID = txOut.maskedAmount.maskedTokenId
        case .v2:
            self.txOutAmountMaskedV2TokenID = txOut.maskedAmount.maskedTokenId
        }
    }
}
