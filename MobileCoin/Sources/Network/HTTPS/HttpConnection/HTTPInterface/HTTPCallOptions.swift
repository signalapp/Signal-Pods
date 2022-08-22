//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct HTTPCallOptions {
    var headers: [String: String]
    var timeoutIntervalForRequest: TimeInterval?
    var timeoutIntervalForResource: TimeInterval?
}

extension HTTPCallOptions {
    public init() {
        self.init(headers: [:], timeoutIntervalForRequest: 30, timeoutIntervalForResource: 30)
    }
}
