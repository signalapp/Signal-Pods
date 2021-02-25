//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable colon

import Foundation
import LibMobileCoin

extension Data32 {
    init(
        withMcMutableBuffer body:
            (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Bool
    ) throws {
        self.init()
        try asMcMutableBuffer { bufferPtr in
            try withMcError { errorPtr in
                body(bufferPtr, &errorPtr)
            }.get()
        }
    }

    init(
        withMcMutableBuffer body:
            (UnsafeMutablePointer<McMutableBuffer>, inout UnsafeMutablePointer<McError>?) -> Int
    ) throws {
        self.init()
        let numBytesReturned = try asMcMutableBuffer { bufferPtr in
            try withMcErrorReturningArrayCount { errorPtr in
                body(bufferPtr, &errorPtr)
            }.get()
        }
        guard numBytesReturned == 32 else {
            // This condition indicates a programming error.
            throw InternalError("LibMobileCoin function returned unexpected byte count " +
                "(\(numBytesReturned)). Expected 32.")
        }
    }

    init(withMcMutableBufferInfallible body: (UnsafeMutablePointer<McMutableBuffer>) -> Bool) {
        self.init()
        asMcMutableBuffer { bufferPtr in
            guard body(bufferPtr) else {
                // This condition indicates a programming error.
                fatalError("Error: \(Self.self).\(#function): Infallible LibMobileCoin function " +
                    "failed.")
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
            fatalError("Error: \(Self.self).\(#function): Infallible LibMobileCoin function " +
                "failed.")
        }
        guard numBytesReturned == 32 else {
            // This condition indicates a programming error.
            fatalError("Error: \(Self.self).\(#function): LibMobileCoin function returned " +
                "unexpected byte count (\(numBytesReturned)). Expected 32.")
        }
    }
}
