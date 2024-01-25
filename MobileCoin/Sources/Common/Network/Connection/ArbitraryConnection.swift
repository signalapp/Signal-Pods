//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class ArbitraryConnection<GrpcService, HttpService> {
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

    var connectionOptionWrapper: ConnectionOptionWrapper<GrpcService, HttpService> {
        inner.accessWithoutLocking.connectionOptionWrapper
    }
}

extension ArbitraryConnection {
    private struct Inner {
        var connectionOptionWrapper: ConnectionOptionWrapper<GrpcService, HttpService>

        init(connectionOptionWrapper: ConnectionOptionWrapper<GrpcService, HttpService>) {
            self.connectionOptionWrapper = connectionOptionWrapper
        }
    }
}
