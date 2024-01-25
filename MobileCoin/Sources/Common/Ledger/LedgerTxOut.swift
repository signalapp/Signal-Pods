//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct LedgerTxOut: TxOutProtocol {
    private let txOut: PartialTxOut
    let globalIndex: UInt64
    let block: BlockMetadata

    init(_ txOut: PartialTxOut, globalIndex: UInt64, block: BlockMetadata) {
        self.txOut = txOut
        self.globalIndex = globalIndex
        self.block = block
    }

    var encryptedMemo: Data66 { txOut.encryptedMemo }
    var commitment: Data32 { txOut.commitment }
    var maskedAmount: MaskedAmount { txOut.maskedAmount }
    var targetKey: RistrettoPublic { txOut.targetKey }
    var publicKey: RistrettoPublic { txOut.publicKey }

    func decrypt(accountKey: AccountKey) -> KnownTxOut? {
        KnownTxOut(self, accountKey: accountKey)
    }
}

extension LedgerTxOut: Equatable {}
extension LedgerTxOut: Hashable {}

extension LedgerTxOut {
    init?(_ txOutRecord: FogView_TxOutRecord, viewKey: RistrettoPrivate) {
        guard let partialTxOut = PartialTxOut(txOutRecord, viewKey: viewKey) else {
            return nil
        }
        let globalIndex = txOutRecord.txOutGlobalIndex
        let block = BlockMetadata(
            index: txOutRecord.blockIndex,
            timestamp: txOutRecord.timestampDate)
        self.init(partialTxOut, globalIndex: globalIndex, block: block)
    }

    init?(_ txOutRecord: FogView_TxOutRecordLegacy, viewKey: RistrettoPrivate) {
        guard let partialTxOut = PartialTxOut(txOutRecord, viewKey: viewKey) else {
            return nil
        }
        let globalIndex = txOutRecord.txOutGlobalIndex
        let block = BlockMetadata(
            index: txOutRecord.blockIndex,
            timestamp: txOutRecord.timestampDate)
        self.init(partialTxOut, globalIndex: globalIndex, block: block)
    }
}

// swiftlint:disable todo
extension LedgerTxOut {
    init?(_ fogTxOutRecordBytes: Data, viewKey: RistrettoPrivate) {
        let legacy_txOutRecord = try? FogView_TxOutRecordLegacy(
                contiguousBytes: fogTxOutRecordBytes)
        let txOutRecord = try? FogView_TxOutRecord(contiguousBytes: fogTxOutRecordBytes)

        // TODO - Temporary fix for serialized data, find workaround and remove legacy proto
        switch (legacy_txOutRecord, txOutRecord) {
        case (.some(let txOutRecord), _):
            guard let partialTxOut = PartialTxOut(txOutRecord, viewKey: viewKey) else { return nil }
            let globalIndex = txOutRecord.txOutGlobalIndex
            let block = BlockMetadata(
                index: txOutRecord.blockIndex,
                timestamp: txOutRecord.timestampDate)
            self.init(partialTxOut, globalIndex: globalIndex, block: block)
        case (_, .some(let txOutRecord)):
            guard let partialTxOut = PartialTxOut(txOutRecord, viewKey: viewKey) else { return nil }
            let globalIndex = txOutRecord.txOutGlobalIndex
            let block = BlockMetadata(
                index: txOutRecord.blockIndex,
                timestamp: txOutRecord.timestampDate)
            self.init(partialTxOut, globalIndex: globalIndex, block: block)
        default:
            return nil
        }
    }
}
// swiftlint:enable todo
