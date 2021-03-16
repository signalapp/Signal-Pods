//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class KeyImageSpentTracker {
    let keyImage: KeyImage

    var spentStatus: KeyImage.SpentStatus

    init(_ keyImage: KeyImage) {
        self.keyImage = keyImage
        self.spentStatus = .unspent(knownToBeUnspentBlockCount: 0)
    }

    var isSpent: Bool {
        if case .spent = spentStatus {
            return true
        } else {
            return false
        }
    }

    var nextKeyImageQueryBlockIndex: UInt64 {
        spentStatus.nextKeyImageQueryBlockIndex
    }
}
