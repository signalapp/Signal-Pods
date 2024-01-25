//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

// HTTP
extension ConnectionSession {
    func processResponse(headers: [AnyHashable: Any]) {
        processCookieHeader(headers: headers)
    }

    func processCookieHeader(headers: [AnyHashable: Any]) {
        let http1Headers = Dictionary(
            headers
                .compactMap({ (key: AnyHashable, value: Any) -> (name: String, value: String)? in
                    guard let name = key as? String else { return nil }
                    guard let value = value as? String else { return nil }
                    return (name:name, value:value)
                })
                .map { ($0.name.capitalized, $0.value) },
            uniquingKeysWith: { k, _ in k }
        )

        let receivedCookies = HTTPCookie.cookies(
            withResponseHeaderFields: http1Headers,
            for: url)
        receivedCookies.forEach(cookieStorage.setCookie)
    }
}

extension ConnectionSession {
    var authorizationHeaders: [String: String] {
        guard let credentials = authorizationCredentials else { return [:] }
        return ["Authorization": credentials.authorizationHeaderValue]
    }

    var cookieHeaders: [String: String] {
        guard let cookies = cookieStorage.cookies(for: url) else { return [:] }
        return HTTPCookie.requestHeaderFields(with: cookies)
    }

    var requestHeaders: [String: String] {
        var headers: [String: String] = [:]
        headers.merge(cookieHeaders) { _, new in new }
        headers.merge(authorizationHeaders) { _, new in new }
        return headers
    }
}
