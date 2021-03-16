//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

/// See https://github.com/satoshilabs/slips/blob/master/slip-0010.md
enum Slip10Utils {
    static func ed25519PrivateKey(fromSeed seed: Data, path: [UInt32]) -> Data32 {
        seed.asMcBuffer { seedPtr in
            let path = Slip10Indices(path)
            return path.withUnsafeOpaquePointer { pathPtr in
                Data32(withMcMutableBufferInfallible: { bufferPtr in
                    mc_slip10_derive_ed25519_private_key(seedPtr, pathPtr, bufferPtr)
                })
            }
        }
    }
}

private final class Slip10Indices {
    private let ptr: OpaquePointer

    init(_ indices: [UInt32]) {
        self.ptr = withMcInfallible(mc_slip10_indices_create)
        for index in indices {
            add(index)
        }
    }

    deinit {
        mc_slip10_indices_free(ptr)
    }

    private func add(_ index: UInt32) {
        withMcInfallible { mc_slip10_indices_add(ptr, index) }
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }
}
