//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct KnownTxOut: TxOutProtocol {
    private let ledgerTxOut: LedgerTxOut
    let amount: Amount
    let keyImage: KeyImage
    let subaddressIndex: UInt64
    let recoverableMemo: RecoverableMemo
    let sharedSecret: RistrettoPrivate

    init?(_ ledgerTxOut: LedgerTxOut, accountKey: AccountKey) {
        guard let amount = ledgerTxOut.amount(accountKey: accountKey),
              let (subaddressIndex, keyImage) = ledgerTxOut.keyImage(accountKey: accountKey),
              let sharedSecret = TxOutUtils.sharedSecret(
                                    viewPrivateKey: accountKey.viewPrivateKey,
                                    publicKey: ledgerTxOut.publicKey),
              let commitment = TxOutUtils.reconstructCommitment(
                                    maskedAmount: ledgerTxOut.maskedAmount,
                                    publicKey: ledgerTxOut.publicKey,
                                    viewPrivateKey: accountKey.viewPrivateKey)
        else {
            return nil
        }

        self.recoverableMemo = TxOutMemoParser.parse(
                                            encryptedPayload: ledgerTxOut.encryptedMemo,
                                            accountKey: accountKey,
                                            txOutKeys: ledgerTxOut.keys)

        self.commitment = commitment
        self.ledgerTxOut = ledgerTxOut
        self.amount = amount
        self.keyImage = keyImage
        self.subaddressIndex = subaddressIndex
        self.sharedSecret = sharedSecret
    }

    var value: UInt64 { amount.value }
    var tokenId: TokenId { amount.tokenId }
    var encryptedMemo: Data66 { ledgerTxOut.encryptedMemo }
    var commitment: Data32
    var maskedAmount: MaskedAmount { ledgerTxOut.maskedAmount }
    var targetKey: RistrettoPublic { ledgerTxOut.targetKey }
    var publicKey: RistrettoPublic { ledgerTxOut.publicKey }
    var block: BlockMetadata { ledgerTxOut.block }
    var globalIndex: UInt64 { ledgerTxOut.globalIndex }
}

extension KnownTxOut: Equatable {}
extension KnownTxOut: Hashable {}
