//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct FixedFeeStrategy: FeeStrategy {
    private let fee: UInt64

    init(fee: UInt64) {
        self.fee = fee
    }

    func fee(numInputs: Int, numOutputs: Int) -> UInt64 {
        fee
    }
}
