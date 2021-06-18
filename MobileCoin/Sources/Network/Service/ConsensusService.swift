//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import LibMobileCoin

protocol ConsensusService {
    func proposeTx(
        _ tx: External_Tx,
        completion: @escaping (Result<ConsensusCommon_ProposeTxResponse, ConnectionError>) -> Void)
}

protocol BlockchainService {
    func getLastBlockInfo(
        completion:
            @escaping (Result<ConsensusCommon_LastBlockInfoResponse, ConnectionError>) -> Void)
}
