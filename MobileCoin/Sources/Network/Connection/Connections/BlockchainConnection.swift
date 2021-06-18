//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin
import SwiftProtobuf

final class BlockchainConnection: Connection, BlockchainService {
    private let client: ConsensusCommon_BlockchainAPIClient

    init(
        config: ConnectionConfig<ConsensusUrl>,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?
    ) {
        let channel = channelManager.channel(for: config)
        self.client = ConsensusCommon_BlockchainAPIClient(channel: channel)
        super.init(config: config, targetQueue: targetQueue)
    }

    func getLastBlockInfo(
        completion:
            @escaping (Result<ConsensusCommon_LastBlockInfoResponse, ConnectionError>) -> Void
    ) {
        performCall(GetLastBlockInfoCall(client: client), completion: completion)
    }
}

extension BlockchainConnection {
    private struct GetLastBlockInfoCall: GrpcCallable {
        let client: ConsensusCommon_BlockchainAPIClient

        func call(
            request: (),
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<ConsensusCommon_LastBlockInfoResponse>) -> Void
        ) {
            let unaryCall =
                client.getLastBlockInfo(Google_Protobuf_Empty(), callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}
