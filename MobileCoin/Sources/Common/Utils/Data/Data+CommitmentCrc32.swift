//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Data {
    // this function is only valid in the following case:
    //  - the Data instance is also a valid Data32
    //  - the Data instance represents a CompressedCommitment
    var commitmentCrc32: UInt32? {
        Data32(self)?.commitmentCrc32
    }
}
