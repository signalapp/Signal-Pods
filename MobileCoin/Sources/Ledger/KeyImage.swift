//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct KeyImage {
    let data32: Data32

    init(_ data: Data32) {
        self.data32 = data
    }

    enum SpentStatus {
        case spent(block: BlockMetadata)
        case unspent(knownToBeUnspentBlockCount: UInt64)

        var nextKeyImageQueryBlockIndex: UInt64 {
            switch self {
            case .spent:
                return 0
            case .unspent(let knownToBeUnspentBlockCount):
                return knownToBeUnspentBlockCount
            }
        }
    }
}

extension KeyImage: DataConvertibleImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        guard let data32 = Data32(data.data) else {
            return nil
        }
        self.init(data32)
    }

    var data: Data { data32.data }
}

extension KeyImage {
    init?(_ keyImage: External_KeyImage) {
        self.init(keyImage.data)
    }
}

extension External_KeyImage {
    init(_ keyImage: KeyImage) {
        self.init(keyImage.data32)
    }
}
