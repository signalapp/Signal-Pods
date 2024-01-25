//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum AttestAkeError: Error {
    case invalidInput(String)
    case attestationVerificationFailed(String)
}

extension AttestAkeError: CustomStringConvertible {
    var description: String {
        "Attest Ake error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .attestationVerificationFailed(let reason):
                return "Attestation verification failed: \(reason)"
            }
        }()
    }
}

enum AeadError: Error {
    case aead(String)
    case cipher(String)
}

extension AeadError: CustomStringConvertible {
    var description: String {
        "Aead error: " + {
            switch self {
            case .aead(let reason):
                return "Aead: \(reason)"
            case .cipher(let reason):
                return "Cipher: \(reason)"
            }
        }()
    }
}

final class AttestAke {
    private var state: State = .unattested

    func authBeginRequest(
        responderId: String,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = nil,
        rngContext: Any? = nil
    ) -> Attest_AuthMessage {
        var request = Attest_AuthMessage()
        request.data = authBeginRequestData(
            responderId: responderId,
            rng: rng,
            rngContext: rngContext)
        return request
    }

    func authBeginRequestData(
        responderId: String,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = nil,
        rngContext: Any? = nil
    ) -> Data {
        let ffi = FfiAttestAke()
        let requestData = ffi.authBeginRequestData(
            responderId: responderId,
            rng: rng,
            rngContext: rngContext)
        state = .authPending(ffi)
        return requestData
    }

    @discardableResult
    func authEnd(authResponse: Attest_AuthMessage, attestationVerifier: AttestationVerifier)
        -> Result<Cipher, AttestAkeError>
    {
        authEnd(authResponseData: authResponse.data, attestationVerifier: attestationVerifier)
    }

    @discardableResult
    func authEnd(authResponseData: Data, attestationVerifier: AttestationVerifier)
        -> Result<Cipher, AttestAkeError>
    {
        guard case .authPending(let attestAke) = state else {
            return .failure(.invalidInput("AttestAke.authEnd called without a pending auth."))
        }

        return attestAke.authEnd(
            authResponseData: authResponseData,
            attestationVerifier: attestationVerifier
        ).map {
            state = .attested(attestAke)
            return Cipher(attestAke)
        }
    }

    var isAttested: Bool {
        if case .attested = state {
            return true
        } else {
            return false
        }
    }

    var cipher: Cipher? {
        if case .attested(let attestAke) = state {
            return Cipher(attestAke)
        } else {
            return nil
        }
    }

    func deattest() {
        state = .unattested
    }
}

extension AttestAke {
    struct Cipher {
        private let ffi: FfiAttestAke

        fileprivate init(_ ffi: FfiAttestAke) {
            self.ffi = ffi
        }

        var binding: Data {
            // Safety: ffi is guaranteed to be attested at this point, so ffi.binding() should
            // never fail.
            ffi.binding
        }

        func encryptMessage(aad: Data, plaintext: Data)
            -> Result<Attest_Message, AeadError>
        {
            var message = Attest_Message()
            message.aad = aad
            message.channelID = binding
            return encrypt(aad: aad, plaintext: plaintext).map {
                message.data = $0
                return message
            }
        }

        func encrypt(aad: Data, plaintext: Data) -> Result<Data, AeadError> {
            ffi.encrypt(aad: aad, plaintext: plaintext)
        }

        func decryptMessage(_ message: Attest_Message) -> Result<Data, AeadError> {
            decrypt(aad: message.aad, ciphertext: message.data)
        }

        func decrypt(aad: Data, ciphertext: Data) -> Result<Data, AeadError> {
            ffi.decrypt(aad: aad, ciphertext: ciphertext)
        }
    }
}

extension AttestAke {
    private enum State {
        case unattested
        case authPending(FfiAttestAke)
        case attested(FfiAttestAke)
    }
}

private final class FfiAttestAke {
    private let ptr: OpaquePointer

    init() {
        // Safety: mc_attest_ake_create should never return nil.
        self.ptr = withMcInfallible(mc_attest_ake_create)
    }

    deinit {
        mc_attest_ake_free(ptr)
    }

    var isAttested: Bool {
        var attested = false
        withMcInfallible {
            mc_attest_ake_is_attested(ptr, &attested)
        }
        return attested
    }

    var binding: Data {
        Data(withMcMutableBufferInfallible: { bufferPtr in
            mc_attest_ake_get_binding(ptr, bufferPtr)
        })
    }

    func authBeginRequestData(
        responderId: String,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = nil,
        rngContext: Any? = nil
    ) -> Data {
        withMcRngCallback(rng: rng, rngContext: rngContext) { rngCallbackPtr in
            Data(withMcMutableBufferInfallible: { bufferPtr in
                mc_attest_ake_get_auth_request(ptr, responderId, rngCallbackPtr, bufferPtr)
            })
        }
    }

    func authEnd(authResponseData: Data, attestationVerifier: AttestationVerifier)
        -> Result<(), AttestAkeError>
    {
        authResponseData.asMcBuffer { bytesPtr in
            attestationVerifier.withUnsafeOpaquePointer { attestationVerifierPtr in
                withMcError { errorPtr in
                    mc_attest_ake_process_auth_response(
                        ptr,
                        bytesPtr,
                        attestationVerifierPtr,
                        &errorPtr)
                }.mapError {
                    switch $0.errorCode {
                    case .invalidInput:
                        return .invalidInput("\(redacting: $0.description)")
                    case .attestationVerificationFailed:
                        return .attestationVerificationFailed("\(redacting: $0.description)")
                    default:
                        // Safety: mc_attest_ake_process_auth_response should not throw
                        // non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }
            }
        }
    }

    func encrypt(aad: Data, plaintext: Data) -> Result<Data, AeadError> {
        aad.asMcBuffer { aadPtr in
            plaintext.asMcBuffer { plaintextPtr in
                Data.make(withMcMutableBuffer: { ciphertextOutPtr, errorPtr in
                    mc_attest_ake_encrypt(ptr, aadPtr, plaintextPtr, ciphertextOutPtr, &errorPtr)
                }).mapError {
                    switch $0.errorCode {
                    case .aead:
                        return .aead("\(redacting: $0.description)")
                    case .cipher:
                        return .cipher("\(redacting: $0.description)")
                    default:
                        // Safety: mc_attest_ake_encrypt should not throw non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }
            }
        }
    }

    func decrypt(aad: Data, ciphertext: Data) -> Result<Data, AeadError> {
        aad.asMcBuffer { aadPtr in
            ciphertext.asMcBuffer { ciphertextPtr in
                Data.make(withEstimatedLengthMcMutableBuffer: ciphertext.count)
                { plaintextOutPtr, errorPtr in
                    mc_attest_ake_decrypt(ptr, aadPtr, ciphertextPtr, plaintextOutPtr, &errorPtr)
                }.mapError {
                    switch $0.errorCode {
                    case .aead:
                        return .aead("\(redacting: $0.description)")
                    case .cipher:
                        return .cipher("\(redacting: $0.description)")
                    default:
                        // Safety: mc_attest_ake_decrypt should not throw non-documented errors.
                        logger.fatalError("Unhandled LibMobileCoin error: \(redacting: $0)")
                    }
                }
            }
        }
    }
}
