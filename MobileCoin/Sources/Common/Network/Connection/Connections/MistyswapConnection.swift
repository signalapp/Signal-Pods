//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable closure_body_length

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class MistyswapConnection: Connection<
        GrpcProtocolConnectionFactory.MistyswapServiceProvider,
        HttpProtocolConnectionFactory.MistyswapServiceProvider
    >,
    MistyswapService
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
                guard let rotatedConfig = config.mistyswapConfig() else {
                    logger.fatalError(
                        "This should never happen, no config passed to create a mistyswap" +
                        " connection. Other checks should have caught this." +
                        " Fix this by using valid mistyswap URLs and attestation")
                }

                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeMistyswapService(
                                config: rotatedConfig,
                                targetQueue: targetQueue,
                                rng: rng,
                                rngContext: rngContext))
                case .http:
                    return .http(
                        httpService:
                            httpFactory.makeMistyswapService(
                                config: rotatedConfig,
                                targetQueue: targetQueue,
                                rng: rng,
                                rngContext: rngContext))
                }
            },
            transportProtocolOption: config.fogViewConfig().transportProtocolOption,
            targetQueue: targetQueue)
    }

    func initiateOfframp(
        request: MistyswapOfframp_InitiateOfframpRequest,
        completion: @escaping (
            Result<MistyswapOfframp_InitiateOfframpResponse, ConnectionError>
        ) -> Void
    ) {
        guard config.mistyswapConfig() != nil else {
            completion(
                .failure(
                    .connectionFailure(
                        "Config used to intialize your client " +
                        "did not include URLs or Attestation info for Mistyswap.")))
            return
        }

        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.initiateOfframp(
                request: request,
                completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.initiateOfframp(
                request: request,
                completion: rotateURLOnError(completion))
        }
    }

    func getOfframpStatus(
        request: MistyswapOfframp_GetOfframpStatusRequest,
        completion: @escaping (
            Result<MistyswapOfframp_GetOfframpStatusResponse, ConnectionError>
        ) -> Void
    ) {
        guard config.mistyswapConfig() != nil else {
            completion(
                .failure(
                    .connectionFailure(
                        "Config used to intialize your client " +
                        "did not include URLs or Attestation info for Mistyswap.")))
            return
        }

        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getOfframpStatus(
                    request: request,
                    completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.getOfframpStatus(
                    request: request,
                    completion: rotateURLOnError(completion))
        }
    }

    func forgetOfframp(
        request: MistyswapOfframp_ForgetOfframpRequest,
        completion: @escaping (
            Result<MistyswapOfframp_ForgetOfframpResponse, ConnectionError>
        ) -> Void
    ) {
        guard config.mistyswapConfig() != nil else {
            completion(
                .failure(
                    .connectionFailure(
                        "Config used to intialize your client " +
                        "did not include URLs or Attestation info for Mistyswap.")))
            return
        }

        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.forgetOfframp(
                    request: request,
                    completion: rotateURLOnError(completion))
        case .http(let httpConnection):
            httpConnection.forgetOfframp(
                    request: request,
                    completion: rotateURLOnError(completion))
        }
    }

}

extension EmptyMistyswapService: ConnectionProtocol { }
