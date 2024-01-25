//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

final class FogKeyImageHttpConnection: AttestedHttpConnection, FogKeyImageService {
    private let client: AuthHttpCallableClientWrapper<FogLedger_FogKeyImageAPIRestClient>
    private let requester: RestApiRequester

    init(
        config: AttestedConnectionConfig<FogUrl>,
        requester: RestApiRequester,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        self.requester = requester
        self.client = AuthHttpCallableClientWrapper(
                client: FogLedger_FogKeyImageAPIRestClient(),
                requester: self.requester)
        super.init(
            client: self.client,
            requester: self.requester,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func checkKeyImages(
        request: FogLedger_CheckKeyImagesRequest,
        completion: @escaping (Result<FogLedger_CheckKeyImagesResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            CheckKeyImagesCall(client: client, requester: self.requester),
            request: request,
            completion: completion)
    }
}

extension FogKeyImageHttpConnection {
    private struct CheckKeyImagesCall: AttestedHttpCallable {
        typealias InnerRequest = FogLedger_CheckKeyImagesRequest
        typealias InnerResponse = FogLedger_CheckKeyImagesResponse

        let client: AuthHttpCallableClientWrapper<FogLedger_FogKeyImageAPIRestClient>
        let requester: RestApiRequester

        func call(
            request: Attest_Message,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<Attest_Message>) -> Void
        ) {
            let unaryCall = client.checkKeyImages(request, callOptions: callOptions)
            requester.makeRequest(call: unaryCall, completion: completion)
        }
    }
}

extension FogKeyImageHttpConnection: FogKeyImageServiceConnection {}
extension FogLedger_FogKeyImageAPIRestClient: AuthHttpCallee, CheckKeyImagesCallee {}
