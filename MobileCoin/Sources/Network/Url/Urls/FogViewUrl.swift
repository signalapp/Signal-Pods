//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

typealias FogViewUrl = MobileCoinUrl<FogViewScheme>

struct FogViewScheme: Scheme {
    static let secureScheme = McConstants.FOG_VIEW_SCHEME_SECURE
    static let insecureScheme = McConstants.FOG_VIEW_SCHEME_INSECURE

    static let defaultSecurePort = McConstants.FOG_VIEW_DEFAULT_SECURE_PORT
    static let defaultInsecurePort = McConstants.FOG_VIEW_DEFAULT_INSECURE_PORT
}
