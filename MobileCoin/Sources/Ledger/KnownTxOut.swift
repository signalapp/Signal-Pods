//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct KnownTxOut: TxOutProtocol {
    private let ledgerTxOut: LedgerTxOut
    let value: UInt64
    let keyImage: KeyImage

    init?(_ ledgerTxOut: LedgerTxOut, accountKey: AccountKey) {
        logger.info("")
        guard let value = ledgerTxOut.value(accountKey: accountKey),
              let keyImage = ledgerTxOut.keyImage(accountKey: accountKey)
        else {
            return nil
        }

        self.ledgerTxOut = ledgerTxOut
        self.value = value
        self.keyImage = keyImage
    }

    var commitment: Data32 { ledgerTxOut.commitment }
    var maskedValue: UInt64 { ledgerTxOut.maskedValue }
    var targetKey: RistrettoPublic { ledgerTxOut.targetKey }
    var publicKey: RistrettoPublic { ledgerTxOut.publicKey }
    var block: BlockMetadata { ledgerTxOut.block }
    var globalIndex: UInt64 { ledgerTxOut.globalIndex }
}

extension KnownTxOut: Equatable {}
extension KnownTxOut: Hashable {}
