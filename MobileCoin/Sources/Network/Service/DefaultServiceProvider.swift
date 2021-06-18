//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class DefaultServiceProvider: ServiceProvider {
    private let targetQueue: DispatchQueue?
    private let channelManager = GrpcChannelManager()

    private let consensus: ConsensusConnection
    private let blockchain: BlockchainConnection
    private let view: FogViewConnection
    private let merkleProof: FogMerkleProofConnection
    private let keyImage: FogKeyImageConnection
    private let block: FogBlockConnection
    private let untrustedTxOut: FogUntrustedTxOutConnection

    private var reportUrlToReportConnection: [GrpcChannelConfig: FogReportConnection] = [:]

    init(networkConfig: NetworkConfig, targetQueue: DispatchQueue?) {
        self.targetQueue = targetQueue
        self.consensus = ConsensusConnection(
            config: networkConfig.consensus,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.blockchain = BlockchainConnection(
            config: networkConfig.blockchain,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.view = FogViewConnection(
            config: networkConfig.fogView,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.merkleProof = FogMerkleProofConnection(
            config: networkConfig.fogMerkleProof,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.keyImage = FogKeyImageConnection(
            config: networkConfig.fogKeyImage,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.block = FogBlockConnection(
            config: networkConfig.fogBlock,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.untrustedTxOut = FogUntrustedTxOutConnection(
            config: networkConfig.fogUntrustedTxOut,
            channelManager: channelManager,
            targetQueue: targetQueue)
    }

    var consensusService: ConsensusService { consensus }
    var blockchainService: BlockchainService { blockchain }
    var fogViewService: FogViewService { view }
    var fogMerkleProofService: FogMerkleProofService { merkleProof }
    var fogKeyImageService: FogKeyImageService { keyImage }
    var fogBlockService: FogBlockService { block }
    var fogUntrustedTxOutService: FogUntrustedTxOutConnection { untrustedTxOut }

    func fogReportService(for fogReportUrl: FogUrl) -> FogReportService {
        let config = GrpcChannelConfig(url: fogReportUrl)
        guard let reportConnection = reportUrlToReportConnection[config] else {
            let reportConnection = FogReportConnection(
                url: fogReportUrl,
                channelManager: channelManager,
                targetQueue: targetQueue)
            reportUrlToReportConnection[config] = reportConnection
            return reportConnection
        }
        return reportConnection
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
}
