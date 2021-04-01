//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

enum FogRngError: Error {
    case invalidKey(String)
    case unsupportedCryptoBoxVersion(String)
}

extension FogRngError: CustomStringConvertible {
    var description: String {
        "Fog Kex Rng error: " + {
            switch self {
            case .invalidKey(let reason):
                return "Invalid key: \(reason)"
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
        logger.info("fogRngKey(pubkey): \(fogRngKey.pubkey)")
        return subaddressViewPrivateKey.asMcBuffer { viewPrivateKeyPtr in
            fogRngKey.pubkey.asMcBuffer { pubkeyPtr in
                withMcError { errorPtr in
                    mc_fog_rng_create(viewPrivateKeyPtr, pubkeyPtr, fogRngKey.version, &errorPtr)
                }.mapError {
                    switch $0.errorCode {
                    case .invalidInput:
                        return .invalidKey("\(redacting: $0.description)")
                    case .unsupportedCryptoBoxVersion:
                        return .unsupportedCryptoBoxVersion("\(redacting: $0.description)")
                    default:
                        // Safety: mc_fog_rng_create should not throw non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }.map { ptr in
                    FogRng(ptr)
                }
            }
        }
    }

    /// - Returns: `.failure` when the input is not deserializable.
    static func make(serializedData: Data) -> Result<FogRng, FogRngError> {
        logger.info("serializedData: \(redacting: serializedData)")
        return serializedData.asMcBuffer { dataPtr in
            withMcError { errorPtr in
                mc_fog_rng_deserialize_proto(dataPtr, &errorPtr)
            }.mapError {
                switch $0.errorCode {
                case .invalidInput:
                    logger.warning("invalid key: \(redacting: $0.description)")
                    return .invalidKey("\(redacting: $0.description)")
                case .unsupportedCryptoBoxVersion:
                    logger.warning("unsupported crypto box version: \(redacting: $0.description)")
                    return .unsupportedCryptoBoxVersion("\(redacting: $0.description)")
                default:
                    // Safety: mc_fog_rng_deserialize_proto should not throw non-documented errors.
                    logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                }
            }
        }.map { ptr in
            FogRng(ptr)
        }
    }

    private let ptr: OpaquePointer
    private let outputSize: Int

    private init(_ ptr: OpaquePointer) {
        logger.info("")
        self.ptr = ptr
        self.outputSize = withMcInfallibleReturningOptional {
            let len = mc_fog_rng_get_output_len(ptr)
            return len >= 0 ? len : nil
        }
    }

    deinit {
        logger.info("")
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
        logger.info("\(count)")
        let rngCopy = clone()
        return (0..<count).map { _ in
            rngCopy.advance()
        }
    }

    @discardableResult
    func advance() -> Data {
        logger.info("")
        return Data(withFixedLengthMcMutableBufferInfallible: outputSize) { bufferPtr in
            mc_fog_rng_advance(ptr, bufferPtr)
        }
    }
}
