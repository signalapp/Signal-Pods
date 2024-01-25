//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol ServiceProvider {
    var consensusService: ConsensusService { get }
    var blockchainService: BlockchainService { get }

    var fogViewService: FogViewService { get }
    var fogMerkleProofService: FogMerkleProofService { get }
    var fogKeyImageService: FogKeyImageService { get }
    var fogBlockService: FogBlockService { get }
    var fogUntrustedTxOutService: FogUntrustedTxOutService { get }

    var mistyswapService: MistyswapService? { get }

    func fogReportService(
        for fogReportUrl: FogUrl,
        completion: @escaping (FogReportService) -> Void
    )

    func setTransportProtocolOption(_ transportProtocolOption: TransportProtocol.Option)

    func setConsensusAuthorization(credentials: BasicCredentials)
    func setFogUserAuthorization(credentials: BasicCredentials)
    func setMistyswapAuthorization(credentials: BasicCredentials)
}
