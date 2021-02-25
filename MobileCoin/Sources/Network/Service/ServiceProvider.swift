//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

protocol ServiceProvider {
    var consensusService: ConsensusService { get }

    var fogViewService: FogViewService { get }
    var fogMerkleProofService: FogMerkleProofService { get }
    var fogKeyImageService: FogKeyImageService { get }
    var fogBlockService: FogBlockService { get }
    var fogUntrustedTxOutService: FogUntrustedTxOutConnection { get }

    func fogReportService(for fogReportUrl: FogReportUrl) -> FogReportService

    func setAuthorization(credentials: BasicCredentials)
}
