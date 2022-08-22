//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

typealias ConnectionWrapperFactory = (TransportProtocol.Option)
                                    -> ConnectionOptionWrapper<
                                        ConnectionProtocol,
                                        ConnectionProtocol
                                    >

public struct TransportProtocol {
    public static let grpc = TransportProtocol(option: .grpc)
    public static let http = TransportProtocol(option: .http)

    let option: Option
}

extension TransportProtocol {
    enum Option {
        case grpc
        case http
    }
}

extension TransportProtocol: CustomStringConvertible {
    public var description: String {
        switch option {
        case .grpc:
            return "GRPC"
        case .http:
            return "HTTP"
        }
    }
}

extension TransportProtocol: Equatable { }
extension TransportProtocol: Hashable { }

extension TransportProtocol {
    var certificateValidator: SSLCertificateValidator {
        switch self.option {
        case .grpc:
            return WrappedNIOSSLCertificateValidator()
        case .http:
            return SecSSLCertificateValidator()
        }
    }
}

protocol SupportedProtocols {
    static var supportedProtocols: [TransportProtocol] { get }
}

extension SupportedProtocols {
    public static var supportedProtocols: [TransportProtocol] { [] }
}
