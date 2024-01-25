//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct FogRngKey {
    let pubkey: Data
    let version: UInt32

    init(pubkey: Data, version: UInt32) {
        self.pubkey = pubkey
        self.version = version
    }
}

extension FogRngKey: Equatable {}
extension FogRngKey: Hashable {}

extension FogRngKey {
    init(_ pubkey: KexRng_KexRngPubkey) {
        self.pubkey = pubkey.pubkey
        self.version = pubkey.version
    }
}

extension KexRng_KexRngPubkey {
    init(_ fogRngKey: FogRngKey) {
        self.init()
        self.pubkey = fogRngKey.pubkey
        self.version = fogRngKey.version
    }
}
