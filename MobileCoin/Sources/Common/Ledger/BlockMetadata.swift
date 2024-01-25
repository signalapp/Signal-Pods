//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct BlockMetadata {
    public let index: UInt64

    let timestampStatus: TimestampStatus?
    public var timestamp: Date? {
        switch timestampStatus {
        case .known(timestamp: let timestamp):
            return timestamp
        case .none, .unavailable, .temporarilyUnknown:
            return nil
        }
    }

    init(index: UInt64, timestamp: Date?) {
        let timestampStatus: TimestampStatus?
        if let timestamp = timestamp {
            timestampStatus = .known(timestamp: timestamp)
        } else {
            timestampStatus = nil
        }
        self.init(index: index, timestampStatus: timestampStatus)
    }

    init(index: UInt64, timestampStatus: TimestampStatus?) {
        self.index = index
        self.timestampStatus = timestampStatus
    }
}

extension BlockMetadata: Equatable {}
extension BlockMetadata: Hashable {}

extension BlockMetadata {
    enum TimestampStatus {
        case known(timestamp: Date)
        case unavailable
        case temporarilyUnknown
    }
}

extension BlockMetadata.TimestampStatus: Equatable {}
extension BlockMetadata.TimestampStatus: Hashable {}
