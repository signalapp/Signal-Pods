//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogBlockConnection: Connection<
        GrpcProtocolConnectionFactory.FogBlockServiceProvider,
        HttpProtocolConnectionFactory.FogBlockServiceProvider
    >,
    FogBlockService
{
    private let httpFactory: HttpProtocolConnectionFactory
    private let grpcFactory: GrpcProtocolConnectionFactory
    private let config: NetworkConfig
    private let targetQueue: DispatchQueue?

    init(
        httpFactory: HttpProtocolConnectionFactory,
        grpcFactory: GrpcProtocolConnectionFactory,
        config: NetworkConfig,
        targetQueue: DispatchQueue?
    ) {
        self.httpFactory = httpFactory
        self.grpcFactory = grpcFactory
        self.config = config
        self.targetQueue = targetQueue

        super.init(
            connectionOptionWrapperFactory: { transportProtocolOption in
                let rotatedConfig = config.fogBlockConfig()
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeFogBlockService(
                                config: rotatedConfig,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeFogBlockService(
                                config: rotatedConfig,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: config.fogBlockConfig().transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getBlocks(request: request, completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.getBlocks(request: request, completion: rotateURLOnError(completion))
        }
    }
}
