//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin
import NIOSSL

final class ConsensusConnection: AttestedConnection, ConsensusService {
    private let client: ConsensusClient_ConsensusClientAPIClient

    init(
        url: ConsensusUrl,
        attestation: Attestation,
        trustRoots: [NIOSSLCertificate]?,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        let channel = channelManager.channel(for: url, trustRoots: trustRoots)
        self.client = ConsensusClient_ConsensusClientAPIClient(channel: channel)
        super.init(
            client: Attest_AttestedApiClient(channel: channel),
            url: url,
            attestation: attestation,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func proposeTx(
        _ tx: External_Tx,
        completion: @escaping (Result<ConsensusCommon_ProposeTxResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            ProposeTxCall(client: client),
            request: tx,
            completion: completion)
    }
}

extension ConsensusConnection {
    private struct ProposeTxCall: AttestedGrpcCallable {
        typealias InnerRequest = External_Tx
        typealias InnerResponse = ConsensusCommon_ProposeTxResponse

        let client: ConsensusClient_ConsensusClientAPIClient

        func call(
            request: Attest_Message,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<ConsensusCommon_ProposeTxResponse>) -> Void
        ) {
            let unaryCall = client.clientTxPropose(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}

extension Attest_AttestedApiClient: AuthGrpcCallableClient {}
