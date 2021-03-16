//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum ReceiptStatus {
    case unknown
    case received(block: BlockMetadata)
    case failed

    init(_ receivedStatus: Receipt.ReceivedStatus) {
        switch receivedStatus {
        case .notReceived:
            self = .unknown
        case .received(block: let block):
            self = .received(block: block)
        case .tombstoneExceeded:
            self = .failed
        }
    }
}
