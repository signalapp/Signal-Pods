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
    var fogUntrustedTxOutService: FogUntrustedTxOutConnection { get }

    func fogReportService(for fogReportUrl: FogUrl) -> FogReportService

    func setConsensusAuthorization(credentials: BasicCredentials)
    func setFogUserAuthorization(credentials: BasicCredentials)
}
