//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

final class FogViewHttpConnection: AttestedHttpConnection, FogViewService {
    private let client: AuthHttpCallableClientWrapper<FogView_FogViewAPIRestClient>
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
                client: FogView_FogViewAPIRestClient(),
                requester: self.requester)
        super.init(
            client: self.client,
            requester: self.requester,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func query(
        requestAad: FogView_QueryRequestAAD,
        request: FogView_QueryRequest,
        completion: @escaping (Result<FogView_QueryResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            EnclaveRequestCall(client: client, requester: requester),
            requestAad: requestAad,
            request: request,
            completion: completion)
    }
}

extension FogViewHttpConnection {
    private struct EnclaveRequestCall: AttestedHttpCallable {
        typealias InnerRequestAad = FogView_QueryRequestAAD
        typealias InnerRequest = FogView_QueryRequest
        typealias InnerResponse = FogView_QueryResponse

        let client: AuthHttpCallableClientWrapper<FogView_FogViewAPIRestClient>
        let requester: RestApiRequester

        func call(
            request: Attest_Message,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<Attest_Message>) -> Void
        ) {
            let clientCall = client.query(request, callOptions: callOptions)
            requester.makeRequest(call: clientCall, completion: completion)
        }
    }
}

extension FogViewHttpConnection: FogViewServiceConnection {}
extension FogView_FogViewAPIRestClient: AuthHttpCallee, QueryHttpCallee {}
