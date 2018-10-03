//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

extension Data {
    public var hexadecimalString: String {
        return (self as NSData).hexadecimalString()
    }

    public func ows_constantTimeIsEqual(to other: Data) -> Bool {
        return (self as NSData).ows_constantTimeIsEqual(to: other)
    }
}
