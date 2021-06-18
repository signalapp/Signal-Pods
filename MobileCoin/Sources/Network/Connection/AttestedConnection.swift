//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable closure_body_length cyclomatic_complexity function_body_length
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
        let inner = Inner(client: client, config: config, rng: rng, rngContext: rngContext)
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
        completion: @escaping (Result<Call.InnerResponse, ConnectionError>) -> Void
    ) where Call.InnerRequestAad == (), Call.InnerResponseAad == () {
        performAttestedCall(call, requestAad: (), request: request, completion: completion)
    }

    func performAttestedCall<Call: AttestedGrpcCallable>(
        _ call: Call,
        requestAad: Call.InnerRequestAad,
        request: Call.InnerRequest,
        completion: @escaping (Result<Call.InnerResponse, ConnectionError>) -> Void
    ) where Call.InnerResponseAad == () {
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
        inner.accessAsync(block: { inner, callback in
            inner.performAttestedCallWithAuth(
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
        private let url: MobileCoinUrlProtocol
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
            self.url = config.url
            self.session = ConnectionSession(config: config)
            self.client = client
            self.attestAke = AttestAke()
            self.responderId = config.url.responderId
            self.attestationVerifier = AttestationVerifier(attestation: config.attestation)
            self.rng = rng
            self.rngContext = rngContext
        }

        func setAuthorization(credentials: BasicCredentials) {
            session.authorizationCredentials = credentials
        }

        func performAttestedCallWithAuth<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                       ConnectionError>
            ) -> Void
        ) {
            doPerformAttestedCallWithAuth(
                call,
                requestAad: requestAad,
                request: request,
                attestAkeCipher: attestAke.cipher.map { ($0, freshCipher: false) },
                completion: completion)
        }

        private func doPerformAttestedCallWithAuth<Call: AttestedGrpcCallable>(
            _ call: Call,
            requestAad: Call.InnerRequestAad,
            request: Call.InnerRequest,
            attestAkeCipher: (AttestAke.Cipher, freshCipher: Bool)?,
            completion: @escaping (
                Result<(responseAad: Call.InnerResponseAad, response: Call.InnerResponse),
                       ConnectionError>
            ) -> Void
        ) {
            if let (attestAkeCipher, freshCipher) = attestAkeCipher {
                logger.info(
                    "Performing attested call... url: \(self.url)",
                    logFunction: false)

                doPerformAttestedCall(
                    call,
                    requestAad: requestAad,
                    request: request,
                    attestAkeCipher: attestAkeCipher
                ) {
                    switch $0 {
                    case .success(let response):
                        logger.info(
                            "Attested call successful. url: \(self.url)",
                            logFunction: false)

                        completion(.success(response))
                    case .failure(.connectionError(let connectionError)):
                        let errorMessage = "Connection failure while performing attested call. " +
                            "url: \(self.url), error: \(connectionError)"
                        switch connectionError {
                        case .connectionFailure, .serverRateLimited:
                            logger.warning(errorMessage, logFunction: false)
                        case .authorizationFailure, .invalidServerResponse,
                             .attestationVerificationFailed, .outdatedClient:
                            logger.error(errorMessage, logFunction: false)
                        }

                        completion(.failure(connectionError))
                    case .failure(.attestationFailure):
                        self.attestAke.deattest()

                        if freshCipher {
                            let errorMessage =
                                "Attestation failure with fresh auth. url: \(self.url)"
                            logger.warning(errorMessage, logFunction: false)

                            completion(.failure(.invalidServerResponse(errorMessage)))
                        } else {
                            logger.info(
                                "Attestation failure using cached auth, reattesting... url: " +
                                    "\(self.url)",
                                logFunction: false)

                            self.doPerformAttestedCallWithAuth(
                                call,
                                requestAad: requestAad,
                                request: request,
                                attestAkeCipher: nil,
                                completion: completion)
                        }
                    }
                }
            } else {
                logger.info(
                    "Peforming attestation... url: \(url)",
                    logFunction: false)

                doPerformAuthCall {
                    switch $0 {
                    case .success(let attestAkeCipher):
                        logger.info(
                            "Attestation successful. url: \(self.url)",
                            logFunction: false)

                        self.doPerformAttestedCallWithAuth(
                            call,
                            requestAad: requestAad,
                            request: request,
                            attestAkeCipher: (attestAkeCipher, freshCipher: true),
                            completion: completion)
                    case .failure(let connectionError):
                        let errorMessage = "Connection failure while performing attestation. " +
                            "url: \(self.url), error: \(connectionError)"
                        switch connectionError {
                        case .connectionFailure, .serverRateLimited:
                            logger.warning(errorMessage, logFunction: false)
                        case .authorizationFailure, .invalidServerResponse,
                             .attestationVerificationFailed, .outdatedClient:
                            logger.error(errorMessage, logFunction: false)
                        }

                        completion(.failure(connectionError))
                    }
                }
            }
        }

        private func doPerformAuthCall(
            completion: @escaping (Result<AttestAke.Cipher, ConnectionError>) -> Void
        ) {
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

                            return .invalidServerResponse(
                                "Attestation failure during auth. url: \(self.url)")
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
            let callOptions = requestCallOptions()

            call.call(request: request, callOptions: callOptions) {
                completion(self.processResponse(callResult: $0))
            }
        }

        private func requestCallOptions() -> CallOptions {
            var callOptions = CallOptions()
            session.addRequestHeaders(to: &callOptions.customMetadata)
            return callOptions
        }

        private func processResponse<Response>(callResult: UnaryCallResult<Response>)
            -> Result<Response, AttestedConnectionError>
        {
            // Basic credential authorization failure
            guard callResult.status.code != .unauthenticated else {
                return .failure(.connectionError(.authorizationFailure("url: \(url)")))
            }

            // Attestation failure, reattest
            guard callResult.status.code != .permissionDenied else {
                return .failure(.attestationFailure())
            }

            guard callResult.status.isOk, let response = callResult.response else {
                return .failure(.connectionError(
                    .connectionFailure("url: \(url), status: \(callResult.status)")))
            }

            if let initialMetadata = callResult.initialMetadata {
                session.processResponse(headers: initialMetadata)
            }

            return .success(response)
        }
    }
}
