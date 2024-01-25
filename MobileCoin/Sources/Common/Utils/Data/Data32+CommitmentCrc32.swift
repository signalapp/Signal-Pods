//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Data32 {
    // this function is only valid in the following case:
    //  - the Data instance represents a CompressedCommitment
    var commitmentCrc32: UInt32? {
        TxOutUtils.calculateCrc32(from: self)
    }
}
