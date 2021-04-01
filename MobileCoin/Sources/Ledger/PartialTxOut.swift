//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct PartialTxOut: TxOutProtocol {
    let commitment: Data32
    let maskedValue: UInt64
    let targetKey: RistrettoPublic
    let publicKey: RistrettoPublic
}

extension PartialTxOut: Equatable {}
extension PartialTxOut: Hashable {}

extension PartialTxOut {
    init(_ txOut: TxOut) {
        self.init(
            commitment: txOut.commitment,
            maskedValue: txOut.maskedValue,
            targetKey: txOut.targetKey,
            publicKey: txOut.publicKey)
    }
}

extension PartialTxOut {
    init?(_ txOut: External_TxOut) {
        logger.info("")
        guard let commitment = Data32(txOut.amount.commitment.data),
              let targetKey = RistrettoPublic(txOut.targetKey.data),
              let publicKey = RistrettoPublic(txOut.publicKey.data)
        else {
            return nil
        }
        self.init(
            commitment: commitment,
            maskedValue: txOut.amount.maskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    init?(_ txOut: FogView_FogTxOut) {
        logger.info("")
        guard let commitment = Data32(txOut.amount.commitment.data),
              let targetKey = RistrettoPublic(txOut.targetKey.data),
              let publicKey = RistrettoPublic(txOut.publicKey.data)
        else {
            return nil
        }
        self.init(
            commitment: commitment,
            maskedValue: txOut.amount.maskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    init?(_ txOutRecord: FogView_TxOutRecord) {
        guard let commitment = Data32(txOutRecord.txOutAmountCommitmentData),
              let targetKey = RistrettoPublic(txOutRecord.txOutTargetKeyData),
              let publicKey = RistrettoPublic(txOutRecord.txOutPublicKeyData)
        else {
            return nil
        }
        self.init(
            commitment: commitment,
            maskedValue: txOutRecord.txOutAmountMaskedValue,
            targetKey: targetKey,
            publicKey: publicKey)
    }
}
