//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct TransactionSubmitter {
    private let consensusService: ConsensusService

    init(consensusService: ConsensusService) {
        self.consensusService = consensusService
    }

    func submitTransaction(
        _ transaction: Transaction,
        completion: @escaping (Result<(), ConnectionError>) -> Void
    ) {
        consensusService.proposeTx(External_Tx(transaction)) {
            completion($0.flatMap { response in
                guard response.result == .ok else {
                    return .failure(.invalidServerResponse(
                        "Failed to submit transaction: \(response.result) " +
                        "(\(response.result.rawValue)), blockCount: \(response.blockCount)"))
                }
                return .success(())
            })
        }
    }
}
