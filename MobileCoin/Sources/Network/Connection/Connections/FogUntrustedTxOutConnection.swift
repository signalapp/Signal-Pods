//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogUntrustedTxOutConnection:
    Connection<GrpcProtocolConnectionFactory.FogUntrustedTxOutServiceProvider, HttpProtocolConnectionFactory.FogUntrustedTxOutServiceProvider>,
    FogUntrustedTxOutService
{
    private let httpFactory: HttpProtocolConnectionFactory
    private let grpcFactory: GrpcProtocolConnectionFactory
    private let config: ConnectionConfig<FogUrl>
    private let targetQueue: DispatchQueue?

    init(
        httpFactory: HttpProtocolConnectionFactory,
        grpcFactory: GrpcProtocolConnectionFactory,
        config: ConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?
    ) {
        self.httpFactory = httpFactory
        self.grpcFactory = grpcFactory
        self.config = config
        self.targetQueue = targetQueue

        super.init(
            connectionOptionWrapperFactory: { transportProtocolOption in
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeFogUntrustedTxOutService(
                                config: config,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeFogUntrustedTxOutService(
                                config: config,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: config.transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getTxOuts(request: request, completion: completion)
        case .http(let httpConnection):
            httpConnection.getTxOuts(request: request, completion: completion)
        }
    }
}
