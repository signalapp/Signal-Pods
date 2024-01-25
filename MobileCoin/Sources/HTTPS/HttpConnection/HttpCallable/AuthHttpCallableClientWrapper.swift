//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
//  swiftlint:disable all

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinHTTP
import LibMobileCoinCommon
#endif


protocol AuthQueryHttpCalleeAndClient : QueryHttpCallee, AuthHttpCallee, HTTPClient {}

struct AuthHttpCallableClientWrapper<WrappedClient:HTTPClient & AuthHttpCallee>: AuthHttpCallableClient, HTTPClient {
    public var defaultHTTPCallOptions: HTTPCallOptions {
        get {
            return client.defaultHTTPCallOptions
        }
        set {
            logger.warning("defaultHTTPOptions set not implemented")
        }
    }
    
    let client : WrappedClient
    let requester: RestApiRequester

    func auth(_ request: Attest_AuthMessage, callOptions: HTTPCallOptions?)
    -> HTTPUnaryCall<Attest_AuthMessage, Attest_AuthMessage> {
        client.auth(request, callOptions: callOptions)
    }
    
    func auth(
        _ request: Attest_AuthMessage,
        callOptions: HTTPCallOptions?,
        completion: @escaping (HttpCallResult<Attest_AuthMessage>) -> Void) {
        
        let clientCall = auth(request, callOptions: callOptions)
        requester.makeRequest(call: clientCall, completion: completion)
    }
}

extension AuthHttpCallableClientWrapper where WrappedClient : QueryHttpCallee {
    func query(
      _ request: Attest_Message,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_Message, Attest_Message> {
        client.query(request, callOptions: callOptions)
    }
}

extension AuthHttpCallableClientWrapper where WrappedClient : OutputsHttpCallee {
    func getOutputs(
      _ request: Attest_Message,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_Message, Attest_Message> {
        client.getOutputs(request, callOptions: callOptions)
    }
}

extension AuthHttpCallableClientWrapper where WrappedClient : CheckKeyImagesCallee {
    func checkKeyImages(
      _ request: Attest_Message,
      callOptions: HTTPCallOptions?
    ) -> HTTPUnaryCall<Attest_Message, Attest_Message> {
        client.checkKeyImages(request, callOptions: callOptions)
    }
}
