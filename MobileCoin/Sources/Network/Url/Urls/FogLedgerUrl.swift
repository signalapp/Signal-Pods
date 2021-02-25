//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

typealias FogLedgerUrl = MobileCoinUrl<FogLedgerScheme>

struct FogLedgerScheme: Scheme {
    static let secureScheme = McConstants.FOG_LEDGER_SCHEME_SECURE
    static let insecureScheme = McConstants.FOG_LEDGER_SCHEME_INSECURE

    static let defaultSecurePort = McConstants.FOG_LEDGER_DEFAULT_SECURE_PORT
    static let defaultInsecurePort = McConstants.FOG_LEDGER_DEFAULT_INSECURE_PORT
}
