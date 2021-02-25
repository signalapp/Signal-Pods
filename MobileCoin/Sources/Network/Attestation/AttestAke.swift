//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

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
    func authEnd(authResponse: Attest_AuthMessage, attestationVerifier: AttestationVerifier) throws
        -> Cipher
    {
        try authEnd(
            authResponseData: authResponse.data,
            attestationVerifier: attestationVerifier)
    }

    @discardableResult
    func authEnd(authResponseData: Data, attestationVerifier: AttestationVerifier) throws
        -> Cipher
    {
        guard case .authPending(let attestAke) = state else {
            throw MalformedInput("\(Self.self).\(#function): Error: authEnd can only be called " +
                "when there is an auth pending.")
        }
        try attestAke.authEnd(
            authResponseData: authResponseData,
            attestationVerifier: attestationVerifier)
        state = .attested(attestAke)
        return Cipher(attestAke)
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

        func encryptMessage(aad: Data, plaintext: Data) throws -> Attest_Message {
            var message = Attest_Message()
            message.aad = aad
            message.channelID = binding
            message.data = try encrypt(aad: aad, plaintext: plaintext)
            return message
        }

        func encrypt(aad: Data, plaintext: Data) throws -> Data {
            try ffi.encrypt(aad: aad, plaintext: plaintext)
        }

        func decryptMessage(_ message: Attest_Message) throws -> Data {
            try decrypt(aad: message.aad, ciphertext: message.data)
        }

        func decrypt(aad: Data, ciphertext: Data) throws -> Data {
            try ffi.decrypt(aad: aad, ciphertext: ciphertext)
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
        mc_attest_ake_is_attested(ptr, &attested)
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
                mc_attest_ake_get_auth_request(
                    ptr,
                    responderId,
                    rngCallbackPtr,
                    bufferPtr)
            })
        }
    }

    func authEnd(authResponseData: Data, attestationVerifier: AttestationVerifier) throws {
        try authResponseData.asMcBuffer { bytesPtr in
            try attestationVerifier.withUnsafeOpaquePointer { attestationVerifierPtr in
                try withMcError { errorPtr in
                    mc_attest_ake_process_auth_response(
                        ptr,
                        bytesPtr,
                        attestationVerifierPtr,
                        &errorPtr)
                }.get()
            }
        }
    }

    func encrypt(aad: Data, plaintext: Data) throws -> Data {
        try aad.asMcBuffer { aadPtr in
            try plaintext.asMcBuffer { plaintextPtr in
                try Data(withMcMutableBuffer: { ciphertextOutPtr, errorPtr in
                    mc_attest_ake_encrypt(ptr, aadPtr, plaintextPtr, ciphertextOutPtr, &errorPtr)
                })
            }
        }
    }

    func decrypt(aad: Data, ciphertext: Data) throws -> Data {
        try aad.asMcBuffer { aadPtr in
            try ciphertext.asMcBuffer { ciphertextPtr in
                try Data(withEstimatedLengthMcMutableBuffer: ciphertext.count)
                { plaintextOutPtr, errorPtr in
                    mc_attest_ake_decrypt(ptr, aadPtr, ciphertextPtr, plaintextOutPtr, &errorPtr)
                }
            }
        }
    }
}
