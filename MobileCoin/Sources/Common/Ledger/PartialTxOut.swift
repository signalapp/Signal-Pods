//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct PartialTxOut: TxOutProtocol {
    let encryptedMemo: Data66
    let maskedAmount: MaskedAmount
    let targetKey: RistrettoPublic
    let publicKey: RistrettoPublic
    var commitment: Data32 { maskedAmount.commitment }
}

extension PartialTxOut: Equatable {}
extension PartialTxOut: Hashable {}

extension PartialTxOut {
    init(_ txOut: TxOut) {
        self.init(
            encryptedMemo: txOut.encryptedMemo,
            maskedAmount: txOut.maskedAmount,
            targetKey: txOut.targetKey,
            publicKey: txOut.publicKey)
    }
}

extension PartialTxOut {
    init?(_ txOut: External_TxOut) {
        guard
            let maskedAmountProto = txOut.maskedAmount,
            let maskedAmount = MaskedAmount(maskedAmountProto)
        else {
            return nil
        }

        guard
            let targetKey = RistrettoPublic(txOut.targetKey.data),
            let publicKey = RistrettoPublic(txOut.publicKey.data),
            [0, 4, 8].contains(maskedAmount.maskedTokenId.count)
        else {
            return nil
        }

        self.init(
            encryptedMemo: txOut.encryptedMemo,
            maskedAmount: maskedAmount,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    init?(_ txOutRecord: FogView_TxOutRecord, viewKey: RistrettoPrivate) {

        guard
            let maskedAmount = MaskedAmount(txOutRecord),
            let targetKey = RistrettoPublic(txOutRecord.txOutTargetKeyData),
            let publicKey = RistrettoPublic(txOutRecord.txOutPublicKeyData),
            [0, 4, 8].contains(maskedAmount.maskedTokenId.count),
            let commitment = TxOutUtils.reconstructCommitment(
                maskedAmount: maskedAmount,
                publicKey: publicKey,
                viewPrivateKey: viewKey),
            Self.isCrc32Matching(commitment, txOutRecord: txOutRecord)
        else {
            return nil
        }

        self.init(
            encryptedMemo: txOutRecord.encryptedMemo,
            maskedAmount: maskedAmount,
            targetKey: targetKey,
            publicKey: publicKey)
    }

    init?(_ txOutRecord: FogView_TxOutRecordLegacy, viewKey: RistrettoPrivate) {

        guard
            let targetKey = RistrettoPublic(txOutRecord.txOutTargetKeyData),
            let publicKey = RistrettoPublic(txOutRecord.txOutPublicKeyData),
            [0, 4, 8].contains(txOutRecord.txOutAmountMaskedTokenID.count),
            let commitment = TxOutUtils.reconstructCommitment(
                maskedValue: txOutRecord.txOutAmountMaskedValue,
                maskedTokenId: txOutRecord.txOutAmountMaskedTokenID,
                maskedAmountVersion: .v1,
                publicKey: publicKey,
                viewPrivateKey: viewKey),
            Self.isCrc32Matching(commitment, txOutRecord: txOutRecord)
        else {
            return nil
        }

        self.init(
            encryptedMemo: txOutRecord.encryptedMemo,
            maskedAmount: MaskedAmount(
                maskedValue: txOutRecord.txOutAmountMaskedValue,
                maskedTokenId: txOutRecord.txOutAmountMaskedTokenID,
                commitment: commitment,
                version: .v1),
            targetKey: targetKey,
            publicKey: publicKey)
    }

    static func isCrc32Matching(
            _ reconstructed: Data32,
            txOutRecord: FogView_TxOutRecordLegacy
    ) -> Bool {
        isCrc32Matching(
            reconstructed,
            commitmentData: txOutRecord.txOutAmountCommitmentData,
            commitmentDataCrc32: txOutRecord.txOutAmountCommitmentDataCrc32)
    }

    static func isCrc32Matching(
            _ reconstructed: Data32,
            txOutRecord: FogView_TxOutRecord
    ) -> Bool {
        isCrc32Matching(
            reconstructed,
            commitmentData: txOutRecord.txOutAmountCommitmentData,
            commitmentDataCrc32: txOutRecord.txOutAmountCommitmentDataCrc32)
    }

    static func isCrc32Matching(
        _ reconstructed: Data32,
        commitmentData: Data,
        commitmentDataCrc32: UInt32
    ) -> Bool {
        let reconstructedCrc32 = reconstructed.commitmentCrc32
        let txIsSentWithCrc32 = (commitmentDataCrc32 != .emptyCrc32)

        // Older code may not set the crc32 value for the tx record,
        // so it must be calculated off the data of the record itself
        // until that code is deprecated.
        //
        // once it is required that crc32 be set, remove the 'else' below
        // and add a guard check for the
        if txIsSentWithCrc32 {
            return reconstructedCrc32 == commitmentDataCrc32
        } else {
            return reconstructedCrc32 == commitmentData.commitmentCrc32
        }
    }
}
