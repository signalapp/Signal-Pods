//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class ConnectionSession {
    static var ephemeralCookieStorage: HTTPCookieStorage {
        guard let cookieStorage = URLSessionConfiguration.ephemeral.httpCookieStorage else {
            // Safety: URLSessionConfiguration.ephemeral.httpCookieStorage will always return
            // non-nil.
            logger.fatalError("URLSessionConfiguration.ephemeral.httpCookieStorage returned nil.")
        }
        return cookieStorage
    }

    let url: URL
    let cookieStorage: HTTPCookieStorage
    var authorizationCredentials: BasicCredentials?

    convenience init(config: ConnectionConfigProtocol) {
        self.init(url: config.url, authorization: config.authorization)
    }

    init(url: MobileCoinUrlProtocol, authorization: BasicCredentials? = nil) {
        self.url = url.httpBasedUrl
        self.cookieStorage = Self.ephemeralCookieStorage
        self.authorizationCredentials = authorization
    }
}
