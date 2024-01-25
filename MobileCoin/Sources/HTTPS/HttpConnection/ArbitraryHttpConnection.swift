//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

class ArbitraryHttpConnection {
    private let inner: SerialDispatchLock<Inner>

    init(url: MobileCoinUrlProtocol, targetQueue: DispatchQueue?) {
        let inner = Inner(url: url)
        self.inner = .init(inner, targetQueue: targetQueue)
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

            let callOptions = $0.requestCallOptions()
            call.call(request: request, callOptions: callOptions, completion: performCallCallback)
        }
    }
}

extension ArbitraryHttpConnection {
    private struct Inner {
        let url: MobileCoinUrlProtocol
        private let session: ConnectionSession

        init(url: MobileCoinUrlProtocol) {
            self.url = url
            self.session = ConnectionSession(url: url)
        }

        func requestCallOptions() -> HTTPCallOptions {
            logger.debug(session.requestHeaders.debugDescription)
            return HTTPCallOptions(headers: session.requestHeaders)
        }

        func processResponse<Response>(callResult: HttpCallResult<Response>)
            -> Result<Response, ConnectionError>
        {
            guard let status = callResult.status else {
                return .failure(.connectionFailure(
                            ["Invalid parameters, request not made.",
                             callResult.error?.localizedDescription, ]
                                .compactMap({ $0 })
                                .joined(separator: " ")))
            }

            guard status.isOk, let response = callResult.response else {
                return .failure(.connectionFailure(String(describing: status)))
            }

            if let headerFields = callResult.allHeaderFields {
                session.processResponse(headers: headerFields)
            }

            return .success(response)
        }
    }
}
