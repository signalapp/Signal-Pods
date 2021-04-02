//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains operator_usage_whitespace

import Foundation
import GRPC
import LibMobileCoin

enum AttestedConnectionError: Error {
    case connectionError(ConnectionError)
    case attestationFailure(String = String())
}

extension AttestedConnectionError: CustomStringConvertible {
    var description: String {
        "Attested connection error: " + {
            switch self {
            case .connectionError(let connectionError):
                return "\(connectionError)"
            case .attestationFailure(let reason):
                return "Attestation failure\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

class AttestedConnection {
    private let inner: SerialCallbackLock<Inner>

    init(
        client: AttestableGrpcClient,
        config: AttestedConnectionConfigProtocol,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        logger.info("")
        let inner = Inner(client: client, config: config, rng: rng, rngContext: rngContext)
        self.inner = .init(inner, targetQueue: targetQueue)
    }

    func setAuthorization(credentials: BasicCredentials) {
        logger.info("")
        inner.priorityAccessAsync {
            $0.setAuthorization(credentials: credentials)
        }
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        request: Call.InnerRequest,
        completion: @escaping (Result<Call.InnerResponse, ConnectionError>) -> Void
    ) where Call.InnerRequestAad == (), Call.InnerResponseAad == () {
        logger.info("")
        performAttestedCall(call, requestAad: (), request: request, completion: completion)
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        requestAad: Call.InnerRequestAad,
        request: Call.InnerRequest,
        completion: @escaping (Result<Call.InnerResponse, ConnectionError>) -> Void
    ) where Call.InnerResponseAad == () {
        logger.info("")
        performAttestedCall(call, requestAad: requestAad, request: request) {
            completion($0.map { $0.response })
        }
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        request: Call.InnerRequest,
        completion: @escaping (
            Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                   ConnectionError>
        ) -> Void
    ) where Call.InnerRequestAad == () {
        logger.info("")
        performAttestedCall(call, requestAad: (), request: request, completion: completion)
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        requestAad: Call.InnerRequestAad,
        request: Call.InnerRequest,
        completion: @escaping (
            Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                   ConnectionError>
        ) -> Void
    ) {
        logger.info("")
        inner.accessAsync(block: { inner, callback in
            inner.performAttestedCall(
                call,
                requestAad: requestAad,
                request: request,
                completion: callback)
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
    private struct Inner {
        private let session: ConnectionSession
        private let client: AttestableGrpcClient
        private let attestAke: AttestAke

        private let responderId: String
        private let attestationVerifier: AttestationVerifier
        private let rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?
        private let rngContext: Any?

        init(
            client: AttestableGrpcClient,
            config: AttestedConnectionConfigProtocol,
            rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
            rngContext: Any? = nil
        ) {
            logger.info("")
            self.session = ConnectionSession(config: config)
            self.client = client
            self.attestAke = AttestAke()
            self.responderId = config.url.responderId
            self.attestationVerifier = AttestationVerifier(attestation: config.attestation)
            self.rng = rng
            self.rngContext = rngContext
        }

        func setAuthorization(credentials: BasicCredentials) {
            logger.info("")
            session.authorizationCredentials = credentials
        }

        func performAttestedCall<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                       ConnectionError>
            ) -> Void
        ) {
            logger.info("")
            if let attestAkeCipher = attestAke.cipher {
                doPerformAttestedCall(
                    call,
                    requestAad: requestAad,
                    request: request,
                    attestAkeCipher: attestAkeCipher
                ) {
                    switch $0 {
                    case .success(let response):
                        completion(.success(response))
                    case .failure(let error):
                        switch error {
                        case .connectionError(let connectionError):
                            completion(.failure(connectionError))
                        case .attestationFailure:
                            self.attestAke.deattest()
                            self.authAndPerformAttestedCall(
                                call,
                                requestAad: requestAad,
                                request: request,
                                completion: completion)
                        }
                    }
                }
            } else {
                authAndPerformAttestedCall(
                    call,
                    requestAad: requestAad,
                    request: request,
                    completion: completion)

            }
        }

        private func authAndPerformAttestedCall<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                       ConnectionError>
            ) -> Void
        ) {
            logger.info("")
            auth {
                guard let attestAkeCipher = $0.successOr(completion: completion) else { return }

                self.doPerformAttestedCall(
                    call,
                    requestAad: requestAad,
                    request: request,
                    attestAkeCipher: attestAkeCipher
                ) {
                    completion($0.mapError {
                        switch $0 {
                        case .connectionError(let connectionError):
                            return connectionError
                        case .attestationFailure:
                            self.attestAke.deattest()
                            return .invalidServerResponse("Attestation failure with fresh auth")
                        }
                    })
                }
            }
        }

        private func auth(
            completion: @escaping (Result<AttestAke.Cipher, ConnectionError>) -> Void
        ) {
            logger.info("")
            let request = attestAke.authBeginRequest(
                responderId: responderId,
                rng: rng,
                rngContext: rngContext)

            doPerformCall(
                AuthGrpcCallableWrapper(authCallable: client.authCallable),
                request: request
            ) {
                completion(
                    $0.mapError {
                        switch $0 {
                        case .connectionError(let connectionError):
                            return connectionError
                        case .attestationFailure:
                            self.attestAke.deattest()
                            return .invalidServerResponse("Attestation failure during auth")
                        }
                    }.flatMap { response in
                        self.attestAke.authEnd(
                            authResponse: response,
                            attestationVerifier: self.attestationVerifier
                        ).mapError {
                            switch $0 {
                            case .invalidInput(let reason):
                                return .invalidServerResponse(reason)
                            case .attestationVerificationFailed(let reason):
                                return .attestationVerificationFailed(reason)
                            }
                        }
                    })
            }
        }

        private func doPerformAttestedCall<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            attestAkeCipher: AttestAke.Cipher,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                       AttestedConnectionError>
            ) -> Void
        ) {
            logger.info("")
            guard let processedRequest =
                    call.processRequest(
                        requestAad: requestAad,
                        request: request,
                        attestAkeCipher: attestAkeCipher)
                    .mapError({ _ in .attestationFailure() })
                    .successOr(completion: completion)
            else { return }

            doPerformCall(call, request: processedRequest) {
                completion($0.flatMap { response in
                    call.processResponse(response: response, attestAkeCipher: attestAkeCipher)
                })
            }
        }

        private func doPerformCall<Call: GrpcCallable>(
            _ call: Call,
            request: Call.Request,
            completion: @escaping (Result<Call.Response, AttestedConnectionError>) -> Void
        ) {
            logger.info("")
            let callOptions = requestCallOptions()

            call.call(request: request, callOptions: callOptions) {
                completion(self.processResponse(callResult: $0))
            }
        }

        private func requestCallOptions() -> CallOptions {
            logger.info("")
            var callOptions = CallOptions()
            session.addRequestHeaders(to: &callOptions.customMetadata)
            return callOptions
        }

        private func processResponse<Response>(callResult: UnaryCallResult<Response>)
            -> Result<Response, AttestedConnectionError>
        {
            logger.info("")
            // Basic credential authorization failure
            guard callResult.status.code != .unauthenticated else {
                logger.info("failure - connectionError - \(String(describing: callResult.status))")
                return .failure(
                    .connectionError(.authorizationFailure(String(describing: callResult.status))))
            }

            // Attestation failure, reattest
            guard callResult.status.code != .permissionDenied else {
                logger.info("failure - attestation failure")
                return .failure(.attestationFailure())
            }

            guard callResult.status.isOk, let response = callResult.response else {
                logger.info(
                    "failure - connection failure - \(String(describing: callResult.status))")
                return .failure(
                    .connectionError(.connectionFailure(String(describing: callResult.status))))
            }

            if let initialMetadata = callResult.initialMetadata {
                session.processResponse(headers: initialMetadata)
            }

            logger.info("success")
            return .success(response)
        }
    }
}
