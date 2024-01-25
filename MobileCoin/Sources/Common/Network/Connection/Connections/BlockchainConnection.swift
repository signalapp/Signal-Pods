//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif
import SwiftProtobuf

final class BlockchainConnection: Connection<
        GrpcProtocolConnectionFactory.BlockchainServiceProvider,
        HttpProtocolConnectionFactory.BlockchainServiceProvider
    >,
    BlockchainService
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
                let rotatedConfig = config.blockchainConfig()
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeBlockchainService(
                                config: rotatedConfig,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeBlockchainService(
                                config: rotatedConfig,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: config.blockchainConfig().transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getLastBlockInfo(
        completion:
            @escaping (Result<ConsensusCommon_LastBlockInfoResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getLastBlockInfo(completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.getLastBlockInfo(completion: rotateURLOnError(completion))
        }
    }
}
