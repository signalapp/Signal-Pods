//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Data {
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0) })
        return value
    }

    func toUInt64() -> UInt64? {
        switch self.count {
        case 0:
            return 0
        case 4:
            guard let value = self.to(type: UInt32.self) else { return nil }
            return UInt64(value)
        case 8:
            return self.to(type: UInt64.self)
        default:
            return nil
        }
    }
}
