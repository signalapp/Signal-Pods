//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct PositiveInt {
    let value: Int

    init?<Value: BinaryInteger>(_ value: Value) {
        guard let value = Int(exactly: value), value > 0 else {
            return nil
        }

        self.value = value
    }
}

struct PositiveUInt64 {
    let value: UInt64

    init?<Value: BinaryInteger>(_ value: Value) {
        guard let value = UInt64(exactly: value), value > 0 else {
            return nil
        }

        self.value = value
    }
}
