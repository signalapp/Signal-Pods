//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

struct UrlParseError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension UrlParseError: CustomStringConvertible {
    public var description: String {
        "URL parsing error: \(reason)"
    }
}

protocol Scheme {
    static var secureScheme: String { get }
    static var insecureScheme: String { get }

    static var defaultSecurePort: Int { get }
    static var defaultInsecurePort: Int { get }
}

protocol MobileCoinUrlProtocol {
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

struct MobileCoinUrl<Scheme: MobileCoin.Scheme>: MobileCoinUrlProtocol {
    let url: URL

    let useTls: Bool
    let host: String
    let port: Int

    init(string: String) throws {
        guard let url = URL(string: string) else {
            throw UrlParseError("Could not parse url: \(string)")
        }
        self.url = url

        switch url.scheme {
        case .some(Scheme.secureScheme):
            self.useTls = true
        case .some(Scheme.insecureScheme):
            self.useTls = false
        default:
            throw UrlParseError("Unrecognized scheme: \(string), " +
                "expected: [\"\(Scheme.secureScheme)\", \"\(Scheme.insecureScheme)\"]")
        }

        guard let host = url.host, !host.isEmpty else {
            throw UrlParseError("Invalid host: \(string)")
        }
        self.host = host

        if let port = url.port {
            self.port = port
        } else {
            self.port = self.useTls ? Scheme.defaultSecurePort : Scheme.defaultInsecurePort
        }
    }
}

struct AnyMobileCoinUrl: MobileCoinUrlProtocol {
    let url: URL

    let useTls: Bool
    let host: String
    let port: Int

    init(string: String) throws {
        try self.init(string: string, useTlsOverride: nil)
    }

    init(string: String, useTls: Bool) throws {
        try self.init(string: string, useTlsOverride: useTls)
    }

    // swiftlint:disable discouraged_optional_boolean
    private init(string: String, useTlsOverride: Bool?) throws {
    // swiftlint:enable discouraged_optional_boolean
        guard let url = URL(string: string) else {
            throw UrlParseError("Could not parse url: \(string)")
        }
        self.url = url

        if let useTls = useTlsOverride {
            self.useTls = useTls
        } else {
            switch url.scheme {
            case "http":
                self.useTls = false
            case "https":
                self.useTls = true
            default:
                self.useTls = true
            }
        }

        guard let host = url.host, !host.isEmpty else {
            throw UrlParseError("Invalid host: \(string)")
        }
        self.host = host

        if let port = url.port {
            self.port = port
        } else if !self.useTls {
            self.port = 80
        } else {
            self.port = 443
        }
    }
}

extension MobileCoinUrl: Equatable {}
extension MobileCoinUrl: Hashable {}
