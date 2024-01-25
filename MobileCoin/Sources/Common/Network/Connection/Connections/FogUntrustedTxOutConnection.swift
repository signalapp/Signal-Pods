//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogUntrustedTxOutConnection: Connection<
        GrpcProtocolConnectionFactory.FogUntrustedTxOutServiceProvider,
        HttpProtocolConnectionFactory.FogUntrustedTxOutServiceProvider
    >,
    FogUntrustedTxOutService
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
                let rotatedConfig = config.fogUntrustedTxOutConfig()
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeFogUntrustedTxOutService(
                                config: rotatedConfig,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeFogUntrustedTxOutService(
                                config: rotatedConfig,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: config.fogUntrustedTxOutConfig().transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getTxOuts(request: request, completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.getTxOuts(request: request, completion: rotateURLOnError(completion))
        }
    }
}
