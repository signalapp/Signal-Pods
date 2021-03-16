//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol FogQueryScalingStrategy {
    func create() -> AnyInfiniteIterator<PositiveInt>
}
