//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct DefaultFogQueryScalingStrategy: FogQueryScalingStrategy {
    private static let MIN_SEARCH_KEYS_PER_QUERY = 10
    private static let MAX_SEARCH_KEYS_PER_QUERY = 200
    private static let SCALING_MULTIPLIER: Double = 3

    func create() -> AnyInfiniteIterator<PositiveInt> {
        var next = Self.MIN_SEARCH_KEYS_PER_QUERY
        return AnyInfiniteIterator {
            guard let current = PositiveInt(next) else {
                // Safety: `next` should always be positive if we only ever increase in value.
                logger.fatalError("PositiveInt.init returned nil. value: \(next)")
            }
            next = min(Int(Double(next) * Self.SCALING_MULTIPLIER), Self.MAX_SEARCH_KEYS_PER_QUERY)
            return current
        }
    }
}
