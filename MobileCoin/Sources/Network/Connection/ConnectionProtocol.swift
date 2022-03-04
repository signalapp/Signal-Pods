//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol ConnectionProtocol {
    func setAuthorization(credentials: BasicCredentials)
}

extension ConnectionProtocol {
    func setAuthorization(credentials: BasicCredentials) {
        // Do nothing
         logger.assertionFailure("ConnectionProtocol not implemented")
    }
}
