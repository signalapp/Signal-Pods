//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum FogRngError: Error {
    case invalidKey
    case unsupportedCryptoBoxVersion(String)
}

extension FogRngError: CustomStringConvertible {
    public var description: String {
        "Fog Kex Rng error: " + {
            switch self {
            case .invalidKey:
                return "Invalid key"
            case .unsupportedCryptoBoxVersion(let reason):
                return "Unsupported CryptoBox version: \(reason)"
            }
        }()
    }
}

final class FogRng {
    static func make(accountKey: AccountKey, fogRngKey: FogRngKey) -> Result<FogRng, FogRngError> {
        make(subaddressViewPrivateKey: accountKey.subaddressViewPrivateKey, fogRngKey: fogRngKey)
    }

    static func make(subaddressViewPrivateKey: RistrettoPrivate, fogRngKey: FogRngKey)
        -> Result<FogRng, FogRngError>
    {
        subaddressViewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            fogRngKey.pubkey.asMcBuffer { pubkeyPtr in
                withMcError({ errorPtr in
                    mc_fog_rng_create(viewPrivateKeyPtr, pubkeyPtr, fogRngKey.version, &errorPtr)
                }).mapError { _ in
                    .invalidKey
                }.map { ptr in
                    FogRng(ptr)
                }
            }
        }
    }

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
