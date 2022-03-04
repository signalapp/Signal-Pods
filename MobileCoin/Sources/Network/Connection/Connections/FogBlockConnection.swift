//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogBlockConnection:
    Connection<GrpcProtocolConnectionFactory.FogBlockServiceProvider, HttpProtocolConnectionFactory.FogBlockServiceProvider>, FogBlockService
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
                            grpcFactory.makeFogBlockService(
                                config: config,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeFogBlockService(
                                config: config,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: config.transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getBlocks(request: request, completion: completion)
        case .http(let httpConnection):
            httpConnection.getBlocks(request: request, completion: completion)
        }
    }
}
