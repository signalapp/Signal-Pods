//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation

final class DefaultServiceProvider: ServiceProvider {
    private let inner: SerialDispatchLock<Inner>

    private let consensus: ConsensusConnection
    private let blockchain: BlockchainConnection
    private let view: FogViewConnection
    private let merkleProof: FogMerkleProofConnection
    private let keyImage: FogKeyImageConnection
    private let block: FogBlockConnection
    private let untrustedTxOut: FogUntrustedTxOutConnection
    private let mistyswap: MistyswapConnection?
    private let grpcConnectionFactory: GrpcProtocolConnectionFactory
    private let httpConnectionFactory: HttpProtocolConnectionFactory

    init(
        networkConfig: NetworkConfig,
        targetQueue: DispatchQueue?,
        grpcConnectionFactory: GrpcProtocolConnectionFactory,
        httpConnectionFactory: HttpProtocolConnectionFactory
    ) {
        self.grpcConnectionFactory = grpcConnectionFactory
        self.httpConnectionFactory = httpConnectionFactory

        let inner = Inner(
                httpFactory: httpConnectionFactory,
                grpcFactory: grpcConnectionFactory,
                targetQueue: targetQueue,
                transportProtocolOption: networkConfig.transportProtocol.option)

        self.inner = .init(inner, targetQueue: targetQueue)

        self.consensus = ConsensusConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)
        self.blockchain = BlockchainConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)
        self.view = FogViewConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)
        self.merkleProof = FogMerkleProofConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)
        self.keyImage = FogKeyImageConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)
        self.block = FogBlockConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)
        self.untrustedTxOut = FogUntrustedTxOutConnection(
            httpFactory: self.httpConnectionFactory,
            grpcFactory: self.grpcConnectionFactory,
            config: networkConfig,
            targetQueue: targetQueue)

        if networkConfig.mistyswapConfig() != nil {
            self.mistyswap = MistyswapConnection(
                httpFactory: self.httpConnectionFactory,
                grpcFactory: self.grpcConnectionFactory,
                config: networkConfig,
                targetQueue: targetQueue)
        } else {
            self.mistyswap = nil
        }
    }

    var consensusService: ConsensusService { consensus }
    var blockchainService: BlockchainService { blockchain }
    var fogViewService: FogViewService { view }
    var fogMerkleProofService: FogMerkleProofService { merkleProof }
    var fogKeyImageService: FogKeyImageService { keyImage }
    var fogBlockService: FogBlockService { block }
    var fogUntrustedTxOutService: FogUntrustedTxOutService { untrustedTxOut }
    var mistyswapService: MistyswapService? { mistyswap }

    func fogReportService(
        for fogReportUrl: FogUrl,
        completion: @escaping (FogReportService) -> Void
    ) {
        inner.accessAsync { completion($0.fogReportService(for: fogReportUrl)) }
    }

    func setTransportProtocolOption(_ transportProtocolOption: TransportProtocol.Option) {
        inner.accessAsync {
            $0.setTransportProtocolOption(transportProtocolOption)
            self.consensus.setTransportProtocolOption(transportProtocolOption)
            self.blockchain.setTransportProtocolOption(transportProtocolOption)
            self.view.setTransportProtocolOption(transportProtocolOption)
            self.merkleProof.setTransportProtocolOption(transportProtocolOption)
            self.keyImage.setTransportProtocolOption(transportProtocolOption)
            self.block.setTransportProtocolOption(transportProtocolOption)
            self.untrustedTxOut.setTransportProtocolOption(transportProtocolOption)
            self.mistyswap?.setTransportProtocolOption(transportProtocolOption)
        }
    }

    func setConsensusAuthorization(credentials: BasicCredentials) {
        consensus.setAuthorization(credentials: credentials)
        blockchain.setAuthorization(credentials: credentials)
    }

    func setFogUserAuthorization(credentials: BasicCredentials) {
        view.setAuthorization(credentials: credentials)
        merkleProof.setAuthorization(credentials: credentials)
        keyImage.setAuthorization(credentials: credentials)
        block.setAuthorization(credentials: credentials)
        untrustedTxOut.setAuthorization(credentials: credentials)
    }

    func setMistyswapAuthorization(credentials: BasicCredentials) {
        mistyswap?.setAuthorization(credentials: credentials)
    }
}

extension DefaultServiceProvider {
    private struct Inner {
        private let httpFactory: HttpProtocolConnectionFactory
        private let grpcFactory: GrpcProtocolConnectionFactory
        private let targetQueue: DispatchQueue?

        private var reportUrlToReportConnection: [FogUrl: FogReportConnection] = [:]
        private(set) var transportProtocolOption: TransportProtocol.Option

        init(
            httpFactory: HttpProtocolConnectionFactory,
            grpcFactory: GrpcProtocolConnectionFactory,
            targetQueue: DispatchQueue?,
            transportProtocolOption: TransportProtocol.Option
        ) {
            self.httpFactory = httpFactory
            self.grpcFactory = grpcFactory
            self.targetQueue = targetQueue
            self.transportProtocolOption = transportProtocolOption
        }

        mutating func fogReportService(for fogReportUrl: FogUrl) -> FogReportService {
            guard let reportConnection = reportUrlToReportConnection[fogReportUrl] else {
                let reportConnection = FogReportConnection(
                    httpFactory: httpFactory,
                    grpcFactory: grpcFactory,
                    url: fogReportUrl,
                    transportProtocolOption: transportProtocolOption,
                    targetQueue: targetQueue)
                reportUrlToReportConnection[fogReportUrl] = reportConnection
                return reportConnection
            }
            return reportConnection
        }

        mutating func setTransportProtocolOption(
            _ transportProtocolOption: TransportProtocol.Option
        ) {
            self.transportProtocolOption = transportProtocolOption
            for reportConnection in reportUrlToReportConnection.values {
                reportConnection.setTransportProtocolOption(transportProtocolOption)
            }
        }
    }
}
