//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

public enum TransactionStatus {
    case unknown
    case pending
    case accepted(block: BlockMetadata)
    case failed

    init(_ acceptedStatus: Transaction.AcceptedStatus) {
        switch acceptedStatus {
        case .notAccepted:
            self = .pending
        case .accepted(block: let block):
            self = .accepted(block: block)
        case .tombstoneBlockExceeded, .inputSpent:
            self = .failed
        }
    }
}
