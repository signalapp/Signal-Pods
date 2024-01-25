//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum FeeLevel {
    case minimum
}

extension FeeLevel {
    var defaultFeeStrategy: FeeStrategy {
        switch self {
        case .minimum:
            return FixedFeeStrategy(fee: McConstants.DEFAULT_MINIMUM_FEE)
        }
    }
}
