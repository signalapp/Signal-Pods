//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin

final class FogUntrustedTxOutConnection: Connection, FogUntrustedTxOutService {
    private let client: FogLedger_FogUntrustedTxOutApiClient

    init(
        url: FogLedgerUrl,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?
    ) {
        let channel = channelManager.channel(for: url)
        self.client = FogLedger_FogUntrustedTxOutApiClient(channel: channel)
        super.init(url: url, targetQueue: targetQueue)
    }

    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, ConnectionError>) -> Void
    ) {
        performCall(GetTxOutsCall(client: client), request: request, completion: completion)
    }
}

extension FogUntrustedTxOutConnection {
    private struct GetTxOutsCall: GrpcCallable {
        let client: FogLedger_FogUntrustedTxOutApiClient

        func call(
            request: FogLedger_TxOutRequest,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<FogLedger_TxOutResponse>) -> Void
        ) {
            let unaryCall = client.getTxOuts(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}
