//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

typealias ConsensusUrl = MobileCoinUrl<ConsensusScheme>

struct ConsensusScheme: Scheme {
    static let secureScheme = McConstants.CONSENSUS_SCHEME_SECURE
    static let insecureScheme = McConstants.CONSENSUS_SCHEME_INSECURE

    static let defaultSecurePort = McConstants.CONSENSUS_DEFAULT_SECURE_PORT
    static let defaultInsecurePort = McConstants.CONSENSUS_DEFAULT_INSECURE_PORT
}
