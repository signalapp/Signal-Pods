//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable colon multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension Data32 {
    static func make(
        withMcMutableBuffer body:
            (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Bool
    ) -> Result<Data32, LibMobileCoinError> {
        var bytes = Data32()
        return bytes.asMcMutableBuffer { bufferPtr in
            withMcError { errorPtr in
                body(bufferPtr, &errorPtr)
            }
        }.map { bytes }
    }

    static func make(
        withMcMutableBuffer body:
            (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Int
    ) -> Result<Data32, LibMobileCoinError> {
        var bytes = Data32()
        return bytes.asMcMutableBuffer { bufferPtr in
            withMcErrorReturningArrayCount { errorPtr in
                body(bufferPtr, &errorPtr)
            }
        }.map { numBytesReturned in
            guard numBytesReturned == 32 else {
                // This condition indicates a programming error.
                logger.fatalError(
                    "LibMobileCoin function returned unexpected byte count " +
                        "(\(numBytesReturned)). Expected 32.")
            }
            return bytes
        }
    }

    init(withMcMutableBufferInfallible body: (UnsafeMutablePointer<McMutableBuffer>) -> Bool) {
        self.init()
        asMcMutableBuffer { bufferPtr in
            guard body(bufferPtr) else {
                // This condition indicates a programming error.
                logger.fatalError("Infallible LibMobileCoin function failed.")
            }
        }
    }

    init(withMcMutableBufferInfallible body: (UnsafeMutablePointer<McMutableBuffer>) -> Int) {
        self.init()
        let numBytesReturned = asMcMutableBuffer { bufferPtr in
            body(bufferPtr)
        }
        guard numBytesReturned > 0 else {
            // This condition indicates a programming error.
            logger.fatalError("Infallible LibMobileCoin function failed.")
        }
        guard numBytesReturned == 32 else {
            // This condition indicates a programming error.
            logger.fatalError(
                "LibMobileCoin function returned unexpected byte count (\(numBytesReturned)). " +
                    "Expected 32.")
        }
    }
}
