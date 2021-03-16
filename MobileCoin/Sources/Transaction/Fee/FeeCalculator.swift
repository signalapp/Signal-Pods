//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct FeeCalculator {
    func fee(numInputs: Int, numOutputs: Int, feeLevel: FeeLevel) -> UInt64 {
        switch feeLevel {
        case .minimum:
            return McConstants.MINIMUM_FEE
        }
    }
}
