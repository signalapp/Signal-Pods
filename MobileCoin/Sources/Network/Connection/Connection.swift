//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class Connection<GrpcService: ConnectionProtocol, HttpService: ConnectionProtocol> {
    private let inner: SerialDispatchLock<Inner>

    private let connectionOptionWrapperFactory: (TransportProtocol.Option)
        -> ConnectionOptionWrapper<GrpcService, HttpService>

    init(
        connectionOptionWrapperFactory: @escaping (TransportProtocol.Option)
            -> ConnectionOptionWrapper<GrpcService, HttpService>,
        transportProtocolOption: TransportProtocol.Option,
        targetQueue: DispatchQueue?
    ) {
        self.connectionOptionWrapperFactory = connectionOptionWrapperFactory
        let connectionOptionWrapper = connectionOptionWrapperFactory(transportProtocolOption)
        let inner = Inner(connectionOptionWrapper: connectionOptionWrapper)
        self.inner = .init(inner, targetQueue: targetQueue)
    }

    func setTransportProtocolOption(_ transportProtocolOption: TransportProtocol.Option) {
        let connectionOptionWrapper = connectionOptionWrapperFactory(transportProtocolOption)
        inner.accessAsync { $0.connectionOptionWrapper = connectionOptionWrapper }
    }

    func setAuthorization(credentials: BasicCredentials) {
        inner.accessAsync { $0.setAuthorization(credentials: credentials) }
    }

    var connectionOptionWrapper: ConnectionOptionWrapper<GrpcService, HttpService> {
        inner.accessWithoutLocking.connectionOptionWrapper
    }
}

extension Connection {
    private struct Inner {
        var connectionOptionWrapper: ConnectionOptionWrapper<GrpcService, HttpService> {
            didSet {
                if let credentials = authorizationCredentials {
                    switch connectionOptionWrapper {
                    case .grpc(grpcService: let grpcService):
                        grpcService.setAuthorization(credentials: credentials)
                    case .http(httpService: let httpService):
                        httpService.setAuthorization(credentials: credentials)
                    }
                }
            }
        }

        private var authorizationCredentials: BasicCredentials?

        init(connectionOptionWrapper: ConnectionOptionWrapper<GrpcService, HttpService>) {
            self.connectionOptionWrapper = connectionOptionWrapper
        }

        mutating func setAuthorization(credentials: BasicCredentials) {
            self.authorizationCredentials = credentials
            switch connectionOptionWrapper {
            case .grpc(grpcService: let grpcService):
                grpcService.setAuthorization(credentials: credentials)
            case .http(httpService: let httpService):
                httpService.setAuthorization(credentials: credentials)
            }
        }
    }
}
