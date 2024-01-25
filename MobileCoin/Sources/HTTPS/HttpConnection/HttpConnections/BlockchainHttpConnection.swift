//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif
import SwiftProtobuf

final class BlockchainHttpConnection: HttpConnection, BlockchainService {
    private let client: ConsensusCommon_BlockchainAPIRestClient
    private let requester: RestApiRequester

    init(
        config: ConnectionConfig<ConsensusUrl>,
        requester: RestApiRequester,
        targetQueue: DispatchQueue?
    ) {
        self.client = ConsensusCommon_BlockchainAPIRestClient()
        self.requester = requester
        super.init(config: config, targetQueue: targetQueue)
    }

    func getLastBlockInfo(
        completion:
            @escaping (Result<ConsensusCommon_LastBlockInfoResponse, ConnectionError>) -> Void
    ) {
        performCall(
                GetLastBlockInfoCall(client: client, requester: requester),
                completion: completion)
    }
}

extension BlockchainHttpConnection {
    private struct GetLastBlockInfoCall: HttpCallable {
        let client: ConsensusCommon_BlockchainAPIRestClient
        let requester: RestApiRequester

        func call(
            request: (),
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<ConsensusCommon_LastBlockInfoResponse>) -> Void
        ) {
            let clientCall = client.getLastBlockInfo(Google_Protobuf_Empty())
            requester.makeRequest(call: clientCall, completion: completion)
        }
    }
}

extension BlockchainHttpConnection: BlockchainServiceConnection {}
