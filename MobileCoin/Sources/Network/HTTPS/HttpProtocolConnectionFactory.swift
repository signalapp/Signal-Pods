//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class HttpProtocolConnectionFactory: ProtocolConnectionFactory {
    let requester: HttpRequester

    init(httpRequester: HttpRequester?) {
        self.requester = httpRequester ?? DefaultHttpRequester()
    }

    func makeConsensusService(
        config: AttestedConnectionConfig<ConsensusUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> ConsensusHttpConnection {
        ConsensusHttpConnection(
                        config: config,
                        requester: RestApiRequester(requester: requester, baseUrl: config.url),
                        targetQueue: targetQueue,
                        rng: rng,
                        rngContext: rngContext)
    }

    func makeBlockchainService(
        config: ConnectionConfig<ConsensusUrl>,
        targetQueue: DispatchQueue?
    ) -> BlockchainHttpConnection {
        BlockchainHttpConnection(
                        config: config,
                        requester: RestApiRequester(requester: requester, baseUrl: config.url),
                        targetQueue: targetQueue)
    }

    func makeFogViewService(
        config: AttestedConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> FogViewHttpConnection {
        FogViewHttpConnection(
                config: config,
                requester: RestApiRequester(requester: requester, baseUrl: config.url),
                targetQueue: targetQueue,
                rng: rng,
                rngContext: rngContext)
    }

    func makeFogMerkleProofService(
        config: AttestedConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> FogMerkleProofHttpConnection {
        FogMerkleProofHttpConnection(
                        config: config,
                        requester: RestApiRequester(requester: requester, baseUrl: config.url),
                        targetQueue: targetQueue,
                        rng: rng,
                        rngContext: rngContext)
    }

    func makeFogKeyImageService(
        config: AttestedConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
        rngContext: Any?
    ) -> FogKeyImageHttpConnection {
        FogKeyImageHttpConnection(
                        config: config,
                        requester: RestApiRequester(requester: requester, baseUrl: config.url),
                        targetQueue: targetQueue,
                        rng: rng,
                        rngContext: rngContext)
    }

    func makeFogBlockService(
        config: ConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?
    ) -> FogBlockHttpConnection {
        FogBlockHttpConnection(
                        config: config,
                        requester: RestApiRequester(requester: requester, baseUrl: config.url),
                        targetQueue: targetQueue)
    }

    func makeFogUntrustedTxOutService(
        config: ConnectionConfig<FogUrl>,
        targetQueue: DispatchQueue?
    ) -> FogUntrustedTxOutHttpConnection {
        FogUntrustedTxOutHttpConnection(
                        config: config,
                        requester: RestApiRequester(requester: requester, baseUrl: config.url),
                        targetQueue: targetQueue)
    }

    func makeFogReportService(
        url: FogUrl,
        transportProtocolOption: TransportProtocol.Option,
        targetQueue: DispatchQueue?
    ) -> FogReportHttpConnection {
        FogReportHttpConnection(
            url: url,
            requester: RestApiRequester(requester: requester, baseUrl: url),
            targetQueue: targetQueue)
    }

//    func makeMistyswapService(
//        config: AttestedConnectionConfig<MistyswapUrl>,
//        targetQueue: DispatchQueue?,
//        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
//        rngContext: Any?
//    ) -> MistyswapHttpConnection {
//        fatalError("HTTP Mistyswap connection not implemented")
//    }
}
