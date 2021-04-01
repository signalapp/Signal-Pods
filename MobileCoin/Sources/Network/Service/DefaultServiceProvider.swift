//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class DefaultServiceProvider: ServiceProvider {
    private let targetQueue: DispatchQueue?
    private let channelManager = GrpcChannelManager()

    private let consensus: ConsensusConnection
    private let view: FogViewConnection
    private let merkleProof: FogMerkleProofConnection
    private let keyImage: FogKeyImageConnection
    private let block: FogBlockConnection
    private let untrustedTxOut: FogUntrustedTxOutConnection

    private var reportUrlToReportConnection: [GrpcChannelConfig: FogReportConnection] = [:]

    init(networkConfig: NetworkConfig, targetQueue: DispatchQueue?) {
        self.targetQueue = targetQueue
        self.consensus = ConsensusConnection(
            url: networkConfig.consensusUrl,
            attestation: networkConfig.consensusAttestation,
            trustRoots: networkConfig.consensusTrustRoots,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.view = FogViewConnection(
            url: networkConfig.fogUrl,
            attestation: networkConfig.fogViewAttestation,
            trustRoots: networkConfig.fogTrustRoots,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.merkleProof = FogMerkleProofConnection(
            url: networkConfig.fogUrl,
            attestation: networkConfig.fogMerkleProofAttestation,
            trustRoots: networkConfig.fogTrustRoots,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.keyImage = FogKeyImageConnection(
            url: networkConfig.fogUrl,
            attestation: networkConfig.fogKeyImageAttestation,
            trustRoots: networkConfig.fogTrustRoots,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.block = FogBlockConnection(
            url: networkConfig.fogUrl,
            trustRoots: networkConfig.fogTrustRoots,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.untrustedTxOut = FogUntrustedTxOutConnection(
            url: networkConfig.fogUrl,
            trustRoots: networkConfig.fogTrustRoots,
            channelManager: channelManager,
            targetQueue: targetQueue)
    }

    var consensusService: ConsensusService { consensus }
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

    func setAuthorization(credentials: BasicCredentials) {
        consensus.setAuthorization(credentials: credentials)
        view.setAuthorization(credentials: credentials)
        merkleProof.setAuthorization(credentials: credentials)
        keyImage.setAuthorization(credentials: credentials)
        block.setAuthorization(credentials: credentials)
        untrustedTxOut.setAuthorization(credentials: credentials)
    }
}
