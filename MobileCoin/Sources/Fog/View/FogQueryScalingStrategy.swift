//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

protocol FogQueryScalingStrategy {
    func create() -> AnyInfiniteIterator<PositiveInt>
}
