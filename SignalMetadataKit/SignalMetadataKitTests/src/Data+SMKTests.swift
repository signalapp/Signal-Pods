//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

extension Data {
    public func prependKeyType() -> Data {
        return (self as NSData).prependKeyType() as Data
    }

    public func removeKeyType() throws -> Data {
        return try (self as NSData).removeKeyType() as Data
    }
}
