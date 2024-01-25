//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

// Can import GRPC so we want the full GRPC Version
#if canImport(LibMobileCoinGRPC)
class GrpcProtocolConnectionFactory: ProtocolConnectionFactory {

    let channelManager = GrpcChannelManager()

    func makeConsensusService(
        config: AttestedConnectionConfig<ConsensusUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> ConsensusGrpcConnection {
        ConsensusGrpcConnection(
                config: config,
                channelManager: channelManager,
                targetQueue: targetQueue,
                rng: rng,
                rngContext: rngContext)
    }

    func makeBlockchainService(
        config: ConnectionConfig<ConsensusUrl>,
        targetQueue: DispatchQueue?
    ) -> BlockchainGrpcConnection {
        BlockchainGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue)
    }

    func makeFogViewService(
        config: AttestedConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> FogViewGrpcConnection {
        FogViewGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func makeFogMerkleProofService(
        config: AttestedConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> FogMerkleProofGrpcConnection {
        FogMerkleProofGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func makeFogKeyImageService(
        config: AttestedConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> FogKeyImageGrpcConnection {
        FogKeyImageGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func makeFogBlockService(
        config: ConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?
    ) -> FogBlockGrpcConnection {
        FogBlockGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue)
    }

    func makeFogUntrustedTxOutService(
        config: ConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?
    ) -> FogUntrustedTxOutGrpcConnection {
        FogUntrustedTxOutGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue)
    }

    func makeFogReportService(
        url: FogUrl,
        transportProtocolOption: TransportProtocol.Option,
        targetQueue: DispatchQueue?
    ) -> FogReportGrpcConnection {
        FogReportGrpcConnection(url: url, channelManager: channelManager, targetQueue: targetQueue)
    }

    func makeMistyswapService(
        config: AttestedConnectionConfig<MistyswapUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> MistyswapGrpcConnection {
        MistyswapGrpcConnection(
            config: config,
            channelManager: channelManager,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func makeEmptyMistyswapService(
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> EmptyMistyswapGrpcConnection {
        EmptyMistyswapGrpcConnection(
            config: EmptyAttestedConnectionConfig(),
            channelManager: channelManager,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }
}
#else

    #if canImport(LibMobileCoinHTTP)
    class GrpcProtocolConnectionFactory: ProtocolConnectionFactory {}
    #else

        // Cannot import either SPM modules
        // Cocoapods version for Core & HTTP Only
        #if canImport(GRPC)
        class GrpcProtocolConnectionFactory: ProtocolConnectionFactory {

            let channelManager = GrpcChannelManager()

            func makeConsensusService(
                config: AttestedConnectionConfig<ConsensusUrl>,
                targetQueue: DispatchQueue?,
                rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
                rngContext: Any?
            ) -> ConsensusGrpcConnection {
                ConsensusGrpcConnection(
                        config: config,
                        channelManager: channelManager,
                        targetQueue: targetQueue,
                        rng: rng,
                        rngContext: rngContext)
            }

            func makeBlockchainService(
                config: ConnectionConfig<ConsensusUrl>,
                targetQueue: DispatchQueue?
            ) -> BlockchainGrpcConnection {
                BlockchainGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue)
            }

            func makeFogViewService(
                config: AttestedConnectionConfig<FogUrl>,
                targetQueue: DispatchQueue?,
                rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
                rngContext: Any?
            ) -> FogViewGrpcConnection {
                FogViewGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue,
                    rng: rng,
                    rngContext: rngContext)
            }

            func makeFogMerkleProofService(
                config: AttestedConnectionConfig<FogUrl>,
                targetQueue: DispatchQueue?,
                rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
                rngContext: Any?
            ) -> FogMerkleProofGrpcConnection {
                FogMerkleProofGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue,
                    rng: rng,
                    rngContext: rngContext)
            }

            func makeFogKeyImageService(
                config: AttestedConnectionConfig<FogUrl>,
                targetQueue: DispatchQueue?,
                rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
                rngContext: Any?
            ) -> FogKeyImageGrpcConnection {
                FogKeyImageGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue,
                    rng: rng,
                    rngContext: rngContext)
            }

            func makeFogBlockService(
                config: ConnectionConfig<FogUrl>,
                targetQueue: DispatchQueue?
            ) -> FogBlockGrpcConnection {
                FogBlockGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue)
            }

            func makeFogUntrustedTxOutService(
                config: ConnectionConfig<FogUrl>,
                targetQueue: DispatchQueue?
            ) -> FogUntrustedTxOutGrpcConnection {
                FogUntrustedTxOutGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue)
            }

            func makeFogReportService(
                url: FogUrl,
                transportProtocolOption: TransportProtocol.Option,
                targetQueue: DispatchQueue?
            ) -> FogReportGrpcConnection {
                FogReportGrpcConnection(
                    url: url,
                    channelManager: channelManager,
                    targetQueue: targetQueue
                )
            }

            func makeMistyswapService(
                config: AttestedConnectionConfig<MistyswapUrl>,
                targetQueue: DispatchQueue?,
                rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
                rngContext: Any?
            ) -> MistyswapGrpcConnection {
                MistyswapGrpcConnection(
                    config: config,
                    channelManager: channelManager,
                    targetQueue: targetQueue,
                    rng: rng,
                    rngContext: rngContext)
            }

            func makeEmptyMistyswapService(
                targetQueue: DispatchQueue?,
                rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
                rngContext: Any?
            ) -> EmptyMistyswapGrpcConnection {
                EmptyMistyswapGrpcConnection(
                    config: EmptyAttestedConnectionConfig(),
                    channelManager: channelManager,
                    targetQueue: targetQueue,
                    rng: rng,
                    rngContext: rngContext)
            }
        }
        #else

        // Cannot import GRPC, so use empty protocol factory
        class GrpcProtocolConnectionFactory: ProtocolConnectionFactory {}
        #endif

    #endif

#endif

    // GRPC-Only
    // Cannot import HTTP, can import GRPC == GRPC-only
    #if canImport(LibMobileCoinHTTP)
    #else

    #if canImport(LibMobileCoinGRPC)
    // GRPC Only SPM, not currently supported
    #else
    #endif

#endif
