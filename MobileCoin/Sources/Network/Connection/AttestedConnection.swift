//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin

class AttestedConnection {
    private let inner: SerialCallbackLock<Inner>

    init(
        client: AttestableGrpcClient,
        url: MobileCoinUrlProtocol,
        attestation: Attestation,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        let inner = Inner(
            client: client,
            url: url,
            attestation: attestation,
            rng: rng,
            rngContext: rngContext)
        self.inner = .init(inner, targetQueue: targetQueue)
    }

    func setAuthorization(credentials: BasicCredentials) {
        inner.priorityAccessAsync {
            $0.setAuthorization(credentials: credentials)
        }
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        request: Call.InnerRequest,
        completion: @escaping (Result<Call.InnerResponse, Error>) -> Void
    ) where Call.InnerRequestAad == (), Call.InnerResponseAad == () {
        performAttestedCall(call, requestAad: (), request: request, completion: completion)
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        requestAad: Call.InnerRequestAad,
        request: Call.InnerRequest,
        completion: @escaping (Result<Call.InnerResponse, Error>) -> Void
    ) where Call.InnerResponseAad == () {
        performAttestedCall(call, requestAad: requestAad, request: request) {
            completion($0.map { $0.response })
        }
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        request: Call.InnerRequest,
        completion: @escaping (
            Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse), Error>
        ) -> Void
    ) where Call.InnerRequestAad == () {
        performAttestedCall(call, requestAad: (), request: request, completion: completion)
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        requestAad: Call.InnerRequestAad,
        request: Call.InnerRequest,
        completion: @escaping (
            Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse), Error>
        ) -> Void
    ) {
        inner.accessAsync(block: { inner, callback in
            do {
                try inner.performAttestedCall(
                    call,
                    requestAad: requestAad,
                    request: request,
                    completion: callback)
            } catch {
                callback(.failure(error))
            }
        }, completion: completion)
    }
}

extension AttestedConnection {
    // Note: Because `SerialCallbackLock` is being used to wrap `AttestedConnection.Inner`, calls
    // to `AttestedConnection.Inner` have exclusive access (other calls will be queued up) until the
    // executing call invokes the completion handler that returns control back to
    // `AttestedConnection`, at which point the block passed to the async `SerialCallbackLock`
    // method that invoked the call to inner will complete and the next async `SerialCallbackLock`
    // access block will execute.
    //
    // This means that calls to `AttestedConnection.Inner` can assume thread-safety until the call
    // invokes the completion handler.
    private class Inner {
        private let session: ConnectionSession
        private let client: AttestableGrpcClient
        private let attestAke: AttestAke

        private let responderId: String
        private let attestationVerifier: AttestationVerifier
        private let rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?
        private let rngContext: Any?

        init(
            client: AttestableGrpcClient,
            url: MobileCoinUrlProtocol,
            attestation: Attestation,
            rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
            rngContext: Any? = nil
        ) {
            self.session = ConnectionSession(url: url)
            self.client = client
            self.attestAke = AttestAke()
            self.responderId = url.responderId
            self.attestationVerifier = AttestationVerifier(attestation: attestation)
            self.rng = rng
            self.rngContext = rngContext
        }

        func setAuthorization(credentials: BasicCredentials) {
            session.authorizationCredentials = credentials
        }

        func performAttestedCall<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse), Error>
            ) -> Void
        ) throws {
            if let attestAkeCipher = attestAke.cipher {
                try doPerformAttestedCall(
                    call,
                    requestAad: requestAad,
                    request: request,
                    attestAkeCipher: attestAkeCipher,
                    completion: completion)
            } else {
                auth { authResult in
                    do {
                        let attestAkeCipher = try authResult.get()

                        try self.doPerformAttestedCall(
                            call,
                            requestAad: requestAad,
                            request: request,
                            attestAkeCipher: attestAkeCipher,
                            completion: completion)
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }

        private func auth(completion: @escaping (Result<AttestAke.Cipher, Error>) -> Void) {
            let request = attestAke.authBeginRequest(
                responderId: responderId,
                rng: rng,
                rngContext: rngContext)

            doPerformCall(
                AuthGrpcCallableWrapper(authCallable: client.authCallable),
                request: request
            ) {
                completion($0.flatMap { response in
                    try self.attestAke.authEnd(
                        authResponse: response,
                        attestationVerifier: self.attestationVerifier)
                })
            }
        }

        private func doPerformAttestedCall<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            attestAkeCipher: AttestAke.Cipher,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse), Error>
            ) -> Void
        ) throws {
            let processedRequest = try call.processRequest(
                requestAad: requestAad,
                request: request,
                attestAkeCipher: attestAkeCipher)

            doPerformCall(call, request: processedRequest) {
                completion($0.flatMap { response in
                    try call.processResponse(response: response, attestAkeCipher: attestAkeCipher)
                })
            }
        }

        private func doPerformCall<Call: GrpcCallable>(
            _ call: Call,
            request: Call.Request,
            completion: @escaping (Result<Call.Response, Error>) -> Void
        ) {
            let callOptions = requestCallOptions()

            call.call(request: request, callOptions: callOptions) { callResult in
                completion(Result {
                    try self.processResponse(callResult: callResult)
                })
            }
        }

        private func requestCallOptions() -> CallOptions {
            var callOptions = CallOptions()
            session.addRequestHeaders(to: &callOptions.customMetadata)
            return callOptions
        }

        private func processResponse<Response>(callResult: UnaryCallResult<Response>) throws
            -> Response
        {
            guard callResult.status.code != .unauthenticated else {
                throw AuthorizationFailure(String(describing: callResult.status))
            }

            guard callResult.status.code != .permissionDenied else {
                attestAke.deattest()
                throw ConnectionFailure(String(describing: callResult.status))
            }

            guard callResult.status.isOk, let response = callResult.response else {
                throw ConnectionFailure(String(describing: callResult.status))
            }

            if let initialMetadata = callResult.initialMetadata {
                session.processResponse(headers: initialMetadata)
            }

            return response
        }
    }
}
