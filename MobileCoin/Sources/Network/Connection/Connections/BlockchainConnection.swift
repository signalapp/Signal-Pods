//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
import SwiftProtobuf

final class BlockchainConnection:
    Connection<GrpcProtocolConnectionFactory.BlockchainServiceProvider, HttpProtocolConnectionFactory.BlockchainServiceProvider>, BlockchainService
{
    private let httpFactory: HttpProtocolConnectionFactory
    private let grpcFactory: GrpcProtocolConnectionFactory
    private let config: ConnectionConfig<ConsensusUrl>
    private let targetQueue: DispatchQueue?

    init(
        httpFactory: HttpProtocolConnectionFactory,
        grpcFactory: GrpcProtocolConnectionFactory,
        config: ConnectionConfig<ConsensusUrl>,
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
                            grpcFactory.makeBlockchainService(
                                config: config,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeBlockchainService(
                                config: config,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: config.transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getLastBlockInfo(
        completion:
            @escaping (Result<ConsensusCommon_LastBlockInfoResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getLastBlockInfo(completion: completion)
        case .http(let httpConnection):
            httpConnection.getLastBlockInfo(completion: completion)
        }
    }
}
