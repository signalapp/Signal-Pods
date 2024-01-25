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


final class FogBlockHttpConnection: HttpConnection, FogBlockService {
    private let client: FogLedger_FogBlockAPIRestClient
    private let requester: RestApiRequester

    init(
        config: ConnectionConfig<FogUrl>,
        requester: RestApiRequester,
        targetQueue: DispatchQueue?
    ) {
        self.client = FogLedger_FogBlockAPIRestClient()
        self.requester = requester
        super.init(config: config, targetQueue: targetQueue)
    }

    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, ConnectionError>) -> Void
    ) {
        performCall(GetBlocksCall(client: client, requester: requester), request: request, completion: completion)
    }
}

extension FogBlockHttpConnection {
    private struct GetBlocksCall: HttpCallable {
        let client: FogLedger_FogBlockAPIRestClient
        let requester: RestApiRequester

        func call(
            request: FogLedger_BlockRequest,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<FogLedger_BlockResponse>) -> Void
        ) {
            let clientCall = client.getBlocks(request, callOptions: callOptions)
            requester.makeRequest(call: clientCall, completion: completion)
        }
    }
}

extension FogBlockHttpConnection: FogBlockServiceConnection {}
