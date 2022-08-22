//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct TxOutContext {
    let txOut: TxOut
    public let receipt: Receipt
    let sharedSecret: RistrettoPublic

    public var sharedSecretBytes: Data {
        sharedSecret.data
    }

    public var txOutPublicKey: Data {
        txOut.publicKey.data
    }

    var confirmation: TxOutConfirmationNumber {
        receipt.confirmationNumber
    }
}

extension TxOutContext: Equatable, Hashable {}

extension TxOutContext {
    init(
        _ txOut: TxOut,
        _ receipt: Receipt,
        _ sharedSecret: RistrettoPublic
    ) {
        self.init(txOut: txOut, receipt: receipt, sharedSecret: sharedSecret)
    }
}
