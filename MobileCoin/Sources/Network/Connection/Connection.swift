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
        inner.accessAsync {
            let callOptions = $0.requestCallOptions()

            call.call(request: request, callOptions: callOptions) { callResult in
                self.inner.accessAsync {
                    completion($0.processResponse(callResult: callResult))
                }
            }
        }
    }
}

extension Connection {
    private struct Inner {
        private let session: ConnectionSession

        init(config: ConnectionConfigProtocol) {
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
                return .failure(.authorizationFailure(String(describing: callResult.status)))
            }

            guard callResult.status.isOk, let response = callResult.response else {
                return .failure(.connectionFailure(String(describing: callResult.status)))
            }

            if let initialMetadata = callResult.initialMetadata {
                session.processResponse(headers: initialMetadata)
            }

            return .success(response)
        }
    }
}
