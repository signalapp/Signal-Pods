//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

struct DefaultFogQueryScalingStrategy: FogQueryScalingStrategy {
    private static let max = 100
    private static let scaling = 1.5

    func create() -> AnyInfiniteIterator<Int> {
        var next = 10
        return AnyInfiniteIterator {
            let current = next
            next = min(Int(Double(current) * Self.scaling), Self.max)
            return current
        }
    }
}
