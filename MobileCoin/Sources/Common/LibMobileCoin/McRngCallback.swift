//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

func withMcRngObjCallback<T>(
    rng: MobileCoinRng,
    _ body: (UnsafeMutablePointer<McRngCallback>?) throws -> T
) rethrows -> T {
    let rawRng = Unmanaged.passUnretained(rng).toOpaque()
    var rngCallback = McRngCallback(rng: mobileCoinRNG, context: rawRng)
    return try body(&rngCallback)
}

func withMcRngCallback<T>(
    rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?,
    rngContext: Any?,
    _ body: (UnsafeMutablePointer<McRngCallback>?) throws -> T
) rethrows -> T {
    if let rng = rng {
        var rngContext = rngContext
        return try withUnsafeMutablePointer(to: &rngContext) { rngContextPtr in
            var rngCallback = McRngCallback(rng: rng, context: rngContextPtr)
            return try body(&rngCallback)
        }
    } else {
        return try body(nil)
    }
}
