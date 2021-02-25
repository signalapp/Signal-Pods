//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

protocol MutableData: DataConvertible, MutableCollection {
    mutating func withUnsafeMutableBytes<ResultType>(
        _ body: (UnsafeMutableRawBufferPointer) throws -> ResultType
    ) rethrows -> ResultType
}

protocol MutableDataImpl: MutableData, DataConvertibleImpl {}
