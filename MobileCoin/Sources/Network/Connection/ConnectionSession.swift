//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import NIOHPACK
import NIOHTTP1

class ConnectionSession {
    private static var ephemeralCookieStorage: HTTPCookieStorage {
        guard let cookieStorage = URLSessionConfiguration.ephemeral.httpCookieStorage else {
            // Safety: URLSessionConfiguration.ephemeral.httpCookieStorage will always return
            // non-nil.
            logger.fatalError("URLSessionConfiguration.ephemeral.httpCookieStorage returned nil.")
        }
        return cookieStorage
    }
    
    private let url: URL
    private let cookieStorage: HTTPCookieStorage
    var authorizationCredentials: BasicCredentials?

    init(url: MobileCoinUrlProtocol) {
        self.url = url.httpBasedUrl
        self.cookieStorage = Self.ephemeralCookieStorage
    }

    func addRequestHeaders(to hpackHeaders: inout HPACKHeaders) {
        addAuthorizationHeader(to: &hpackHeaders)
        addCookieHeader(to: &hpackHeaders)
    }

    func processResponse(headers: HPACKHeaders) {
        processCookieHeader(headers: headers)
    }
}

extension ConnectionSession {
    private func addAuthorizationHeader(to hpackHeaders: inout HPACKHeaders) {
        if let credentials = authorizationCredentials {
            hpackHeaders.add(httpHeaders: ["Authorization": credentials.authorizationHeaderValue])
        }
    }
}

extension ConnectionSession {
    private func addCookieHeader(to hpackHeaders: inout HPACKHeaders) {
        if let cookies = cookieStorage.cookies(for: url) {
            hpackHeaders.add(httpHeaders: HTTPCookie.requestHeaderFields(with: cookies))
        }
    }

    private func processCookieHeader(headers: HPACKHeaders) {
        let http1Headers = Dictionary(
            headers.map { ($0.name.capitalized, $0.value) },
            uniquingKeysWith: { k, _ in k })

        let receivedCookies = HTTPCookie.cookies(
            withResponseHeaderFields: http1Headers,
            for: url)
        receivedCookies.forEach(cookieStorage.setCookie)
    }
}

extension HPACKHeaders {
    fileprivate mutating func add(httpHeaders: [String: String]) {
        add(httpHeaders: HTTPHeaders(Array(httpHeaders)))
    }

    fileprivate mutating func add(httpHeaders: HTTPHeaders) {
        add(contentsOf: HPACKHeaders(httpHeaders: httpHeaders))
    }
}
