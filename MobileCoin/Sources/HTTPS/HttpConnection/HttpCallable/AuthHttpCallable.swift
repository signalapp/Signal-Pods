//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

protocol AuthHttpCallable {
    var requester: RestApiRequester { get }

    func auth(
        _ request: Attest_AuthMessage,
        callOptions: HTTPCallOptions?,
        completion: @escaping (HttpCallResult<Attest_AuthMessage>) -> Void
    )
}

protocol AuthHttpCallee {
    func auth(
      _ request: Attest_AuthMessage,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_AuthMessage, Attest_AuthMessage>
}

protocol QueryHttpCallee {
    func query(
      _ request: Attest_Message,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_Message, Attest_Message>
}

protocol OutputsHttpCallee {
    func getOutputs(
      _ request: Attest_Message,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_Message, Attest_Message>
}

protocol CheckKeyImagesCallee {
    func checkKeyImages(
      _ request: Attest_Message,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_Message, Attest_Message>
}

struct AuthHttpCallableWrapper: HttpCallable {
    let authCallable: AuthHttpCallable
    let requester: RestApiRequester

    func call(
        request: Attest_AuthMessage,
        callOptions: HTTPCallOptions?,
        completion: @escaping (HttpCallResult<Attest_AuthMessage>) -> Void
    ) {
        authCallable.auth(request, callOptions: callOptions, completion: completion)
    }
}
