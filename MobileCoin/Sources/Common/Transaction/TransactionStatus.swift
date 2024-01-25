//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum TransactionStatus {
    case unknown
    case accepted(block: BlockMetadata)
    case failed

    init(_ acceptedStatus: Transaction.AcceptedStatus) {
        switch acceptedStatus {
        case .notAccepted:
            self = .unknown
        case .accepted(block: let block):
            self = .accepted(block: block)
        case .tombstoneBlockExceeded, .inputSpent:
            self = .failed
        }
    }
}
