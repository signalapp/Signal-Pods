//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import Security

func securityRNG(context: UnsafeMutableRawPointer? = nil) -> UInt64 {
    withMcInfallibleReturningOptional {
        Data.secRngGenBytes(MemoryLayout<UInt64>.size).toUInt64()
    }
}

func mobileCoinRNG(context: UnsafeMutableRawPointer?) -> UInt64 {
    // get MobileCoinRng sub-class from context
    guard let context = context else {
        logger.fatalError("Failed to obtain rng from context")
    }

    let rng = Unmanaged<MobileCoinRng>.fromOpaque(context).takeUnretainedValue()
    let val = rng.next()

    return val
}
