//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct HTTPCallOptions {
    public var headers: [String: String]
    public var timeoutIntervalForRequest: TimeInterval?
    public var timeoutIntervalForResource: TimeInterval?
}

extension HTTPCallOptions {
    public init() {
        self.init(headers: [:], timeoutIntervalForRequest: 30, timeoutIntervalForResource: 30)
    }
    
    public init(headers: [String: String]) {
        self.init(headers: headers, timeoutIntervalForRequest: 30, timeoutIntervalForResource: 30)
    }
}
