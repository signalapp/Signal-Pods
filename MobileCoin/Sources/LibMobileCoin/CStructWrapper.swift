//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol CStructWrapper {
    associatedtype CStruct

    func withUnsafeCStructPointer<R>(
        _ body: (UnsafePointer<CStruct>) throws -> R
    ) rethrows -> R
}

extension Optional where Wrapped: CStructWrapper {
    func withUnsafeCStructPointer<R>(
        _ body: (UnsafePointer<Wrapped.CStruct>?) throws -> R
    ) rethrows -> R {
        if let unwrapped = self {
            return try unwrapped.withUnsafeCStructPointer { ptr in
                try body(ptr)
            }
        } else {
            return try body(nil)
        }
    }
}
