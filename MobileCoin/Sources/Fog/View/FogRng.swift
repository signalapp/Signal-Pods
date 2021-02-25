//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogRng {
    private let ptr: OpaquePointer
    private let outputSize: Int

    /// - Returns: `nil` when the input is not deserializable.
    convenience init?(serializedData: Data) {
        guard case .success(let ptr) = serializedData.asMcBuffer({ dataPtr in
            withMcError { errorPtr in
                mc_fog_rng_deserialize_proto(dataPtr, &errorPtr)
            }
        }) else {
            return nil
        }
        self.init(ptr)
    }

    convenience init(accountKey: AccountKey, fogRngKey: FogRngKey) throws {
        try self.init(
            subaddressViewPrivateKey: accountKey.subaddressViewPrivateKey,
            fogRngKey: fogRngKey)
    }

    convenience init(subaddressViewPrivateKey: RistrettoPrivate, fogRngKey: FogRngKey) throws {
        self.init(try subaddressViewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            try fogRngKey.pubkey.asMcBuffer { pubkeyPtr in
                try withMcError { errorPtr in
                    mc_fog_rng_create(viewPrivateKeyPtr, pubkeyPtr, fogRngKey.version, &errorPtr)
                }.get()
            }
        })
    }

    private init(_ ptr: OpaquePointer) {
        self.ptr = ptr
        self.outputSize = withMcInfallibleReturningOptional {
            let len = mc_fog_rng_get_output_len(ptr)
            return len >= 0 ? len : nil
        }
    }

    deinit {
        mc_fog_rng_free(ptr)
    }

    var serializedData: Data {
        Data(withMcMutableBufferInfallible: { bufferPtr in
            mc_fog_rng_serialize_proto(ptr, bufferPtr)
        })
    }

    func clone() -> FogRng {
        // Safety: mc_fog_rng_clone should never return nil.
        FogRng(withMcInfallible { mc_fog_rng_clone(ptr) })
    }

    var index: UInt64 {
        withMcInfallibleReturningOptional {
            let res = mc_fog_rng_index(ptr)
            return res >= 0 ? UInt64(res) : nil
        }
    }

    var output: Data {
        Data(withFixedLengthMcMutableBufferInfallible: outputSize) { bufferPtr in
            mc_fog_rng_peek(ptr, bufferPtr)
        }
    }

    func outputs(count: Int) -> [Data] {
        let rngCopy = clone()
        return (0..<count).map { _ in
            rngCopy.advance()
        }
    }

    @discardableResult
    func advance() -> Data {
        Data(withFixedLengthMcMutableBufferInfallible: outputSize) { bufferPtr in
            mc_fog_rng_advance(ptr, bufferPtr)
        }
    }
}
