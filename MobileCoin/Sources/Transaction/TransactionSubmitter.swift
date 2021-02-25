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
        completion: @escaping (Result<(), Error>) -> Void
    ) {
        consensusService.proposeTx(External_Tx(transaction)) {
            completion($0.flatMap { response in
                guard response.result == .ok else {
                    throw ConnectionFailure("Failed to submit transaction: \(response.result) " +
                        "(\(response.result.rawValue)), blockCount: \(response.blockCount)")
                }
            })
        }
    }
}
