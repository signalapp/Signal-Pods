//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

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

        /// - Returns: `nil` when `blockCount` exceeds our knowledge about the spent status.
        func status(atBlockCount blockCount: UInt64) -> SpentStatus? {
            switch self {
            case .spent(block: let spentAtBlock):
                guard spentAtBlock.index < blockCount else {
                    return nil
                }
                return .spent(block: spentAtBlock)
            case .unspent(knownToBeUnspentBlockCount: let knownToBeUnspentBlockCount):
                guard knownToBeUnspentBlockCount >= blockCount else {
                    return nil
                }
                return .unspent(knownToBeUnspentBlockCount: blockCount)
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
