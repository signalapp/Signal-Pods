//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin
import NIOSSL

final class FogBlockConnection: Connection, FogBlockService {
    private let client: FogLedger_FogBlockAPIClient

    init(
        config: ConnectionConfig<FogUrl>,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?
    ) {
        let channel = channelManager.channel(for: config)
        self.client = FogLedger_FogBlockAPIClient(channel: channel)
        super.init(config: config, targetQueue: targetQueue)
    }

    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, ConnectionError>) -> Void
    ) {
        performCall(GetBlocksCall(client: client), request: request, completion: completion)
    }
}

extension FogBlockConnection {
    private struct GetBlocksCall: GrpcCallable {
        let client: FogLedger_FogBlockAPIClient

        func call(
            request: FogLedger_BlockRequest,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<FogLedger_BlockResponse>) -> Void
        ) {
            let unaryCall = client.getBlocks(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}
