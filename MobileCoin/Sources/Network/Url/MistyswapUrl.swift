//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

typealias MistyswapUrl = MobileCoinUrl<MistyswapScheme>

struct MistyswapScheme: Scheme {
    static let secureScheme = McConstants.MISTYSWAP_SCHEME_SECURE
    static let insecureScheme = McConstants.MISTYSWAP_SCHEME_INSECURE

    static let defaultSecurePort = McConstants.MISTYSWAP_DEFAULT_SECURE_PORT
    static let defaultInsecurePort = McConstants.MISTYSWAP_DEFAULT_INSECURE_PORT
}
