//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC

class ArbitraryConnection {
    private let inner: SerialDispatchLock<Inner>

    init(url: MobileCoinUrlProtocol, targetQueue: DispatchQueue?) {
        let inner = Inner(url: url)
        self.inner = .init(inner, targetQueue: targetQueue)
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

extension ArbitraryConnection {
    private struct Inner {
        private let session: ConnectionSession

        init(url: MobileCoinUrlProtocol) {
            self.session = ConnectionSession(url: url)
        }

        func requestCallOptions() -> CallOptions {
            var callOptions = CallOptions()
            session.addRequestHeaders(to: &callOptions.customMetadata)
            return callOptions
        }

        func processResponse<Response>(callResult: UnaryCallResult<Response>)
            -> Result<Response, ConnectionError>
        {
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
