//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

class HttpConnection: ConnectionProtocol {
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

    func performCall<Call: HttpCallable>(
        _ call: Call,
        request: Call.Request,
        completion: @escaping (Result<Call.Response, ConnectionError>) -> Void
    ) {
        func performCallCallback(callResult: HttpCallResult<Call.Response>) {
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

            call.call(
                    request: request,
                    callOptions: $0.requestCallOptions(),
                    completion: performCallCallback)
        }
    }

    func performCall<Call: HttpCallable>(
        _ call: Call,
        completion: @escaping (Result<Call.Response, ConnectionError>) -> Void
    ) where Call.Request == () {
        performCall(call, request: (), completion: completion)
    }
}

extension HttpConnection {
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

        func requestCallOptions() -> HTTPCallOptions {
            logger.debug(session.requestHeaders.debugDescription)
            return HTTPCallOptions(headers: session.requestHeaders)
        }

        func processResponse<Response>(callResult: HttpCallResult<Response>)
            -> Result<Response, ConnectionError>
        {

            guard let status = callResult.status else {
                let message = "Invalid parameters, request not made."
                return .failure(.connectionFailure(
                    [message, callResult.error?.localizedDescription]
                     .compactMap({ $0 })
                     .joined(separator: " "))
                )
            }

            guard [403, 401].contains(status.code) == false else {
                return .failure(.authorizationFailure("url: \(url)"))
            }

            guard status.isOk, let response = callResult.response else {
                return .failure(.connectionFailure("url: \(url), status: \(status)"))
            }

            if let headerFields = callResult.allHeaderFields {
                session.processResponse(headers: headerFields)
            }

            return .success(response)
        }
    }
}
