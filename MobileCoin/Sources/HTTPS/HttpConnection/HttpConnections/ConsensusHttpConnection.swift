//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

final class ConsensusHttpConnection: AttestedHttpConnection, ConsensusService {
    private let client: ConsensusClient_ConsensusClientAPIRestClient
    private let requester: RestApiRequester

    init(
        config: AttestedConnectionConfig<ConsensusUrl>,
        requester: RestApiRequester,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        // Solve for shared channel TLS/Certs
        self.requester = requester
        self.client = ConsensusClient_ConsensusClientAPIRestClient()
        let clientWrapper = AuthHttpCallableClientWrapper(
                client: Attest_AttestedApiRestClient(),
                requester: self.requester)
        super.init(
            client: clientWrapper,
            requester: self.requester,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func proposeTx(
        _ tx: External_Tx,
        completion: @escaping (Result<ConsensusCommon_ProposeTxResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            ProposeTxCall(client: client, requester: requester),
            request: tx,
            completion: completion)
    }
}

extension ConsensusHttpConnection {
    private struct ProposeTxCall: AttestedHttpCallable {
        typealias InnerRequest = External_Tx
        typealias InnerResponse = ConsensusCommon_ProposeTxResponse

        let client: ConsensusClient_ConsensusClientAPIRestClient
        let requester: RestApiRequester

        func call(
            request: Attest_Message,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<ConsensusCommon_ProposeTxResponse>) -> Void
        ) {
            let clientCall = client.clientTxPropose(request, callOptions: callOptions)
            requester.makeRequest(call: clientCall, completion: completion)
        }
    }
}

extension ConsensusHttpConnection: ConsensusServiceConnection {}
extension Attest_AttestedApiRestClient: AuthHttpCallee {}
