//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

final class FogUntrustedTxOutHttpConnection: HttpConnection, FogUntrustedTxOutService {
    private let client: FogLedger_FogUntrustedTxOutApiRestClient
    private let requester: RestApiRequester

    init(
        config: ConnectionConfig<FogUrl>,
        requester: RestApiRequester,
        targetQueue: DispatchQueue?
    ) {
        self.client = FogLedger_FogUntrustedTxOutApiRestClient()
        self.requester = requester
        super.init(config: config, targetQueue: targetQueue)
    }

    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, ConnectionError>) -> Void
    ) {
        performCall(
                GetTxOutsCall(client: client, requester: self.requester),
                request: request,
                completion: completion)
    }
}

extension FogUntrustedTxOutHttpConnection {
    private struct GetTxOutsCall: HttpCallable {
        let client: FogLedger_FogUntrustedTxOutApiRestClient
        let requester: RestApiRequester

        func call(
            request: FogLedger_TxOutRequest,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<FogLedger_TxOutResponse>) -> Void
        ) {
            let unaryCall = client.getTxOuts(request, callOptions: callOptions)
            requester.makeRequest(call: unaryCall, completion: completion)
        }
    }
}

extension FogUntrustedTxOutHttpConnection: FogUntrustedTxOutServiceConnection {}
