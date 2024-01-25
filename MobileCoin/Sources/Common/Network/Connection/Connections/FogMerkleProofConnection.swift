//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogMerkleProofConnection: Connection<
        GrpcProtocolConnectionFactory.FogMerkleProofServiceProvider,
        HttpProtocolConnectionFactory.FogMerkleProofServiceProvider
    >,
    FogMerkleProofService
{
    private let httpFactory: HttpProtocolConnectionFactory
    private let grpcFactory: GrpcProtocolConnectionFactory
    private let config: NetworkConfig
    private let targetQueue: DispatchQueue?
    private let rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?
    private let rngContext: Any?

    init(
        httpFactory: HttpProtocolConnectionFactory,
        grpcFactory: GrpcProtocolConnectionFactory,
        config: NetworkConfig,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        self.httpFactory = httpFactory
        self.grpcFactory = grpcFactory
        self.config = config
        self.targetQueue = targetQueue
        self.rng = rng
        self.rngContext = rngContext

        super.init(
            connectionOptionWrapperFactory: { transportProtocolOption in
                let rotatedConfig = config.fogMerkleProofConfig()
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeFogMerkleProofService(
                                config: rotatedConfig,
                                targetQueue: targetQueue,
                                rng: rng,
                                rngContext: rngContext))
                case .http:
                    return .http(httpService:
                            httpFactory.makeFogMerkleProofService(
                                config: rotatedConfig,
                                targetQueue: targetQueue,
                                rng: rng,
                                rngContext: rngContext))
                }
            },
            transportProtocolOption: config.fogMerkleProofConfig().transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getOutputs(
        request: FogLedger_GetOutputsRequest,
        completion: @escaping (Result<FogLedger_GetOutputsResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getOutputs(request: request, completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.getOutputs(request: request, completion: rotateURLOnError(completion))
        }
    }
}
