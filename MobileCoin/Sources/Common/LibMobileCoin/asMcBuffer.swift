// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension DataConvertible {
    func asMcBuffer<T>(_ body: (UnsafePointer<McBuffer>) throws -> T) rethrows -> T {
        try data.withUnsafeBytes {
            let ptr = $0.bindMemory(to: UInt8.self)
            guard let bufferPtr = ptr.baseAddress else {
                // This indicates a programming error. Pointer returned from withUnsafeBytes
                // shouldn't have a nil baseAddress.
                logger.fatalError("ptr.baseAddress == nil.")
            }
            var buffer = McBuffer(buffer: bufferPtr, len: ptr.count)
            return try body(&buffer)
        }
    }
}

extension MutableData {
    mutating func asMcMutableBuffer<T>(
        _ body: (UnsafeMutablePointer<McMutableBuffer>) throws -> T
    ) rethrows -> T {
        try withUnsafeMutableBytes {
            let ptr = $0.bindMemory(to: UInt8.self)
            guard let bufferPtr = ptr.baseAddress else {
                // This indicates a programming error. Pointer returned from withUnsafeMutableBytes
                // shouldn't have a nil baseAddress.
                logger.fatalError("ptr.baseAddress == nil.")
            }
            var buffer = McMutableBuffer(buffer: bufferPtr, len: ptr.count)
            return try body(&buffer)
        }
    }
}

extension Optional where Wrapped: DataConvertible {
    func asOptMcBuffer<T>(_ body: (UnsafePointer<McBuffer>?) throws -> T) rethrows -> T {
        if let unwrapped = self {
            return try unwrapped.asMcBuffer(body)
        } else {
            return try body(nil)
        }
    }
}
