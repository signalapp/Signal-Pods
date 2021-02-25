//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

struct PreparedTxInput {
    let knownTxOut: KnownTxOut
    let ring: [(TxOut, TxOutMembershipProof)]
    let realInputIndex: Int

    init(knownTxOut: KnownTxOut, ring: [(TxOut, TxOutMembershipProof)]) throws {
        let ring = ring.sorted { ring1, ring2 in
            ring1.0.publicKey.data.lexicographicallyPrecedes(ring2.0.publicKey.data)
        }

        guard let realInputIndex = ring.firstIndex(where: { txOut, _ in
            knownTxOut.publicKey == txOut.publicKey
        }) else {
            throw MalformedInput("TxOut not found in ring")
        }

        self.knownTxOut = knownTxOut
        self.ring = ring
        self.realInputIndex = realInputIndex
    }
}
