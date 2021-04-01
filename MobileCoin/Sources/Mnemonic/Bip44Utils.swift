//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// See https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki
enum Bip44Utils {
    /// See https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki#purpose
    static let PURPOSE: UInt32 = 44

    /// See entry 866: https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    static let MOBILECOIN_SLIP44_INDEX: UInt32 = 866

    static func ed25519PrivateKey(fromSeed seed: Data, accountIndex: UInt32) -> Data32 {
        Slip10Utils.ed25519PrivateKey(
            fromSeed: seed,
            path: [PURPOSE, MOBILECOIN_SLIP44_INDEX, accountIndex])
    }
}
