//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

typealias FogReportUrl = MobileCoinUrl<FogScheme>

struct FogScheme: Scheme {
    static let secureScheme = McConstants.FOG_SCHEME_SECURE
    static let insecureScheme = McConstants.FOG_SCHEME_INSECURE

    static let defaultSecurePort = McConstants.FOG_DEFAULT_SECURE_PORT
    static let defaultInsecurePort = McConstants.FOG_DEFAULT_INSECURE_PORT
}
