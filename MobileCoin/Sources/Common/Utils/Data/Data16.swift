//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable implicit_getter

import Foundation

struct Data16 {
    private(set) var data: Data

    /// Initialize with a repeating byte pattern
    ///
    /// - parameter repeatedValue: A byte to initialize the pattern
    init(repeating repeatedValue: UInt8) {
        self.data = Data(repeating: repeatedValue, count: 16)
    }

    /// Initialize with zeroed bytes.
    init() {
        self.data = Data(count: 16)
    }
}

extension Data16: MutableDataImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        guard data.count == 16 else {
            return nil
        }
        self.data = data
    }

    mutating func withUnsafeMutableBytes<ResultType>(
        _ body: (UnsafeMutableRawBufferPointer) throws -> ResultType
    ) rethrows -> ResultType {
        try data.withUnsafeMutableBytes(body)
    }

    /// Sets or returns the byte at the specified index.
    subscript(index: Int) -> UInt8 {
        get { data[index] }
        set { data[index] = newValue }
    }

    subscript(bounds: Range<Int>) -> Data {
        get { data[bounds] }
        set { data[bounds] = newValue }
    }
}
