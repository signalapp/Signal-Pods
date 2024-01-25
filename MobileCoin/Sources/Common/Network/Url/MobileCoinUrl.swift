//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol Scheme {
    static var secureScheme: String { get }
    static var insecureScheme: String { get }

    static var defaultSecurePort: Int { get }
    static var defaultInsecurePort: Int { get }
}

protocol MobileCoinUrlProtocol: CustomStringConvertible {
    var url: URL { get }
    var host: String { get }
    var port: Int { get }
    var useTls: Bool { get }
    var address: String { get }
    var httpBasedUrl: URL { get }
}

extension MobileCoinUrlProtocol {
    var address: String { "\(host):\(port)" }

    /// host:port
    var responderId: String { address }

    var httpBasedUrl: URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        components.scheme = self.useTls ? "https" : "http"
        if components.port == nil {
            switch (components.scheme, self.port) {
            case ("http", 80):
                break
            case ("https", 443):
                break
            case (_, let port):
                components.port = port
            }
        }

        guard let httpUrl = components.url else {
            return url
        }
        return httpUrl
    }
}

struct MobileCoinUrl<URLScheme: Scheme>: MobileCoinUrlProtocol {

    // convenience method that takes an array of url strings and returns a
    // resulting array of MobileCoinUrl only if all strings are valid
    static func make(strings: [String]) -> Result<[MobileCoinUrl], InvalidInputError> {
        guard !strings.isEmpty else {
            return .failure(InvalidInputError("String url array cannot be empty"))
        }

        var mcUrls: [MobileCoinUrl] = []
        for string in strings {
            let result = make(string: string)
            switch result {
            case .success(let mcUrl):
                mcUrls.append(mcUrl)
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(mcUrls)
    }

    static func make(string: String) -> Result<MobileCoinUrl, InvalidInputError> {
        guard let url = URL(string: string) else {
            return .failure(InvalidInputError("Could not parse url: \(string)"))
        }

        let useTls: Bool
        switch url.scheme {
        case .some(URLScheme.secureScheme):
            useTls = true
        case .some(URLScheme.insecureScheme):
            useTls = false
        default:
            return .failure(InvalidInputError("Unrecognized scheme: \(string), expected: " +
                "[\"\(URLScheme.secureScheme)\", \"\(URLScheme.insecureScheme)\"]"))
        }

        guard let host = url.host, !host.isEmpty else {
            return .failure(InvalidInputError("Invalid host: \(string)"))
        }

        return .success(MobileCoinUrl(url: url, useTls: useTls, host: host))
    }

    let url: URL

    let useTls: Bool
    let host: String
    let port: Int

    private init(url: URL, useTls: Bool, host: String) {
        self.url = url
        self.useTls = useTls
        self.host = host

        if let port = url.port {
            self.port = port
        } else {
            self.port = self.useTls ? URLScheme.defaultSecurePort : URLScheme.defaultInsecurePort
        }
    }
}

extension MobileCoinUrl: Equatable {}
extension MobileCoinUrl: Hashable {}

extension MobileCoinUrl: CustomStringConvertible {
    var description: String {
        url.description
    }
}
