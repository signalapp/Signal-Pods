//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable colon multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension Data {
    static func make(
        withMcMutableBuffer body:
            (UnsafeMutablePointer<McMutableBuffer>?, inout UnsafeMutablePointer<McError>?) -> Int
    ) -> Result<Data, LibMobileCoinError> {
        withMcErrorReturningArrayCount { errorPtr in
            // Call body() with nil to get number of bytes.
            body(nil, &errorPtr)
        }.flatMap { numBytes in
            // Call body() again with a pointer to the output buffer.
            var bytes = Data(repeating: 0, count: numBytes)
            return bytes.asMcMutableBuffer { bufferPtr in
                withMcErrorReturningArrayCount { errorPtr in
                    body(bufferPtr, &errorPtr)
                }
            }.map { numBytesWritten in
                guard numBytesWritten <= numBytes else {
                    // This condition indicates a programming error.
                    logger.fatalError(
                        "numBytesWritten (\(numBytesWritten)) must be <= numBytes (\(numBytes))")
                }

                return bytes.prefix(numBytesWritten)
            }
        }
    }

    static func make(
        withFixedLengthMcMutableBuffer numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Bool
    ) -> Result<Data, LibMobileCoinError> {
        var bytes = Data(repeating: 0, count: numBytes)
        return bytes.asMcMutableBuffer { bufferPtr in
            withMcError { errorPtr in
                body(bufferPtr, &errorPtr)
            }
        }.map { bytes }
    }

    static func make(
        withEstimatedLengthMcMutableBuffer numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Int
    ) -> Result<Data, LibMobileCoinError> {
        var bytes = Data(repeating: 0, count: numBytes)
        return bytes.asMcMutableBuffer { bufferPtr in
            withMcErrorReturningArrayCount { errorPtr in
                body(bufferPtr, &errorPtr)
            }
        }.map { numBytesReturned in
            guard numBytesReturned <= numBytes else {
                // This condition indicates a programming error.
                logger.fatalError(
                    "Number of bytes returned from LibMobileCoin (\(numBytesReturned)) is " +
                        "greater than estimated (\(numBytes))")
            }

            return bytes.prefix(numBytesReturned)
        }
    }

    init(
        withFixedLengthMcMutableBufferInfallible numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>) -> Bool
    ) {
        self.init(repeating: 0, count: numBytes)
        let success = asMcMutableBuffer { bufferPtr in
            body(bufferPtr)
        }
        guard success else {
            // This condition indicates a programming error.
            logger.fatalError("Infallible Unsafe Mutable Data Allocation failed.")
        }
    }

    init(withMcMutableBufferInfallible body: (UnsafeMutablePointer<McMutableBuffer>?) -> Int) {
        // Call body() with nil to get number of bytes.
        let numBytes = body(nil)
        guard numBytes >= 0 else {
            // This condition indicates a programming error.
            logger.fatalError("Infallible LibMobileCoin function failed.")
        }

        var bytes = Data(repeating: 0, count: numBytes)
        let numBytesWritten = bytes.asMcMutableBuffer { bufferPtr in
            body(bufferPtr)
        }
        guard numBytesWritten >= 0 else {
            // This condition indicates a programming error.
            logger.fatalError("Infallible LibMobileCoin function failed.")
        }

        guard numBytesWritten <= numBytes else {
            // This condition indicates a programming error.
            logger.fatalError(
                "numBytesWritten (\(numBytesWritten)) must be <= numBytes (\(numBytes))")
        }

        self = bytes.prefix(numBytesWritten)
    }

    init(
        withEstimatedLengthMcMutableBufferInfallible numBytes: Int,
        body: (UnsafeMutablePointer<McMutableBuffer>) -> Int
    ) {
        var bytes = Data(repeating: 0, count: numBytes)
        let numBytesReturned = bytes.asMcMutableBuffer(body)
        guard numBytesReturned <= numBytes else {
            // This condition indicates a programming error.
            logger.fatalError(
                "Number of bytes returned from LibMobileCoin \(numBytesReturned) is greater than " +
                    "estimated \(numBytes)")
        }

        self = bytes.prefix(numBytesReturned)
    }
}
