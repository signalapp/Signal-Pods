//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol FeeStrategy {
    func fee(numInputs: Int, numOutputs: Int) -> UInt64
}
