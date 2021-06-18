//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC

class Connection {
    private let inner: SerialDispatchLock<Inner>

    init(config: ConnectionConfigProtocol, targetQueue: DispatchQueue?) {
        let inner = Inner(config: config)
        self.inner = .init(inner, targetQueue: targetQueue)
    }

    func setAuthorization(credentials: BasicCredentials) {
        inner.accessAsync {
            $0.setAuthorization(credentials: credentials)
        }
    }

    func performCall<Call: GrpcCallable>(
        _ call: Call,
        request: Call.Request,
        completion: @escaping (Result<Call.Response, ConnectionError>) -> Void
    ) {
        func performCallCallback(callResult: UnaryCallResult<Call.Response>) {
            inner.accessAsync {
                let result = $0.processResponse(callResult: callResult)
                switch result {
                case .success:
                    logger.info("Call complete. url: \($0.url)", logFunction: false)
                case .failure(let connectionError):
                    let errorMessage =
                        "Connection failure. url: \($0.url), error: \(connectionError)"
                    switch connectionError {
                    case .connectionFailure, .serverRateLimited:
                        logger.warning(errorMessage, logFunction: false)
                    case .authorizationFailure, .invalidServerResponse,
                         .attestationVerificationFailed, .outdatedClient:
                        logger.error(errorMessage, logFunction: false)
                    }
                }
                completion(result)
            }
        }

        inner.accessAsync {
            logger.info("Performing call... url: \($0.url)", logFunction: false)

            let callOptions = $0.requestCallOptions()
            call.call(request: request, callOptions: callOptions, completion: performCallCallback)
        }
    }

    func performCall<Call: GrpcCallable>(
        _ call: Call,
        completion: @escaping (Result<Call.Response, ConnectionError>) -> Void
    ) where Call.Request == () {
        performCall(call, request: (), completion: completion)
    }
}

extension Connection {
    private struct Inner {
        let url: MobileCoinUrlProtocol
        private let session: ConnectionSession

        init(config: ConnectionConfigProtocol) {
            self.url = config.url
            self.session = ConnectionSession(config: config)
        }

        func setAuthorization(credentials: BasicCredentials) {
            session.authorizationCredentials = credentials
        }

        func requestCallOptions() -> CallOptions {
            var callOptions = CallOptions()
            session.addRequestHeaders(to: &callOptions.customMetadata)
            return callOptions
        }

        func processResponse<Response>(callResult: UnaryCallResult<Response>)
            -> Result<Response, ConnectionError>
        {
            guard callResult.status.code != .unauthenticated else {
                return .failure(.authorizationFailure("url: \(url)"))
            }

            guard callResult.status.isOk, let response = callResult.response else {
                return .failure(.connectionFailure("url: \(url), status: \(callResult.status)"))
            }

            if let initialMetadata = callResult.initialMetadata {
                session.processResponse(headers: initialMetadata)
            }

            return .success(response)
        }
    }
}
