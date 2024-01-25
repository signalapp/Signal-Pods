//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

protocol AuthHttpCallableClient: AttestableHttpClient, AuthHttpCallable {
    func auth(_ request: Attest_AuthMessage, callOptions: HTTPCallOptions?)
        -> HTTPUnaryCall<Attest_AuthMessage, Attest_AuthMessage>
}

extension AuthHttpCallableClient {
    var authCallable: AuthHttpCallable {
        self
    }
}

extension AuthHttpCallableClient {
    func auth(
        _ request: Attest_AuthMessage,
        callOptions: HTTPCallOptions?,
        completion: @escaping (HttpCallResult<Attest_AuthMessage>) -> Void
    ) {
        let clientCall = auth(request, callOptions: callOptions)
        requester.makeRequest(call: clientCall, completion: completion)
    }
}
