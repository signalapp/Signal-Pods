//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable colon

import Foundation
import LibMobileCoin

extension Data {
    init(
        withMcMutableBuffer body:
            (UnsafeMutablePointer<McMutableBuffer>?, inout UnsafeMutablePointer<McError>?) -> Int
    ) throws {
        // Call body() with nil to get number of bytes
        let numBytes = try withMcErrorReturningArrayCount { errorPtr in
            body(nil, &errorPtr)
        }.get()

        // Call body() again with a pointer to the output buffer
        var bytes = Data(repeating: 0, count: numBytes)
        let numBytesWritten = try bytes.asMcMutableBuffer { bufferPtr in
            try withMcErrorReturningArrayCount { errorPtr in
                body(bufferPtr, &errorPtr)
            }.get()
        }

        guard numBytesWritten <= numBytes else {
            throw InternalError("\(#function): numBytesWritten (\(numBytesWritten)) must be <= " +
                "numBytes (\(numBytes))")
        }

        self = bytes.prefix(numBytesWritten)
    }

    init(withMcMutableBufferInfallible body: (UnsafeMutablePointer<McMutableBuffer>?) -> Int) {
        // Call body() with nil to get number of bytes
        let numBytes = body(nil)
        guard numBytes >= 0 else {
            // This condition indicates a programming error.
            fatalError("Error: \(#function): Infallible LibMobileCoin function failed.")
        }

        var bytes = Data(repeating: 0, count: numBytes)
        let numBytesWritten = bytes.asMcMutableBuffer { bufferPtr in
            body(bufferPtr)
        }
        guard numBytesWritten >= 0 else {
            // This condition indicates a programming error.
            fatalError("Error: \(#function): Infallible LibMobileCoin function failed.")
        }

        guard numBytesWritten <= numBytes else {
            // This condition indicates a programming error.
            fatalError("\(#function): numBytesWritten (\(numBytesWritten)) must be <= numBytes " +
                "(\(numBytes))")
        }

        self = bytes.prefix(numBytesWritten)
    }

    init(
        withFixedLengthMcMutableBuffer numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Bool
    ) throws {
        var bytes = Data(repeating: 0, count: numBytes)
        try bytes.asMcMutableBuffer { bufferPtr in
            try withMcError { errorPtr in
                body(bufferPtr, &errorPtr)
            }.get()
        }
        self = bytes
    }

    init(
        withFixedLengthMcMutableBufferInfallible numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>) -> Bool
    ) {
        var bytes = Data(repeating: 0, count: numBytes)
        let success = bytes.asMcMutableBuffer { bufferPtr in
            body(bufferPtr)
        }
        guard success else {
            // This condition indicates a programming error.
            fatalError("Error: \(#function): Infallible LibMobileCoin function failed.")
        }

        self = bytes
    }

    init(
        withEstimatedLengthMcMutableBuffer numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Int
    ) throws {
        var bytes = Data(repeating: 0, count: numBytes)
        let numBytesReturned = try bytes.asMcMutableBuffer { bufferPtr in
            try withMcErrorReturningArrayCount { errorPtr in
                body(bufferPtr, &errorPtr)
            }.get()
        }
        guard numBytesReturned <= numBytes else {
            // This condition indicates a programming error.
            throw InternalError("Number of bytes returned from LibMobileCoin " +
                "(\(numBytesReturned)) is greater than estimated (\(numBytes))")
        }

        self = bytes.prefix(numBytesReturned)
    }

    init(
        withEstimatedLengthMcMutableBufferInfallible numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>) -> Int
    ) {
        var bytes = Data(repeating: 0, count: numBytes)
        let numBytesReturned = bytes.asMcMutableBuffer(body)
        guard numBytesReturned <= numBytes else {
            // This condition indicates a programming error.
            fatalError("Error: \(#function): Number of bytes returned from LibMobileCoin " +
                "\(numBytesReturned) is greater than estimated \(numBytes)")
        }

        self = bytes.prefix(numBytesReturned)
    }
}
