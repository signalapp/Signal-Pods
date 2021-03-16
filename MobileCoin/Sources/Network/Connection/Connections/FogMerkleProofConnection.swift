//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin
import NIOSSL

final class FogMerkleProofConnection: AttestedConnection, FogMerkleProofService {
    private let client: FogLedger_FogMerkleProofAPIClient

    init(
        url: FogUrl,
        attestation: Attestation,
        trustRoots: [NIOSSLCertificate]?,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        let channel = channelManager.channel(for: url, trustRoots: trustRoots)
        self.client = FogLedger_FogMerkleProofAPIClient(channel: channel)
        super.init(
            client: self.client,
            url: url,
            attestation: attestation,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func getOutputs(
        request: FogLedger_GetOutputsRequest,
        completion: @escaping (Result<FogLedger_GetOutputsResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            GetOutputsCall(client: client),
            request: request,
            completion: completion)
    }
}

extension FogMerkleProofConnection {
    private struct GetOutputsCall: AttestedGrpcCallable {
        typealias InnerRequest = FogLedger_GetOutputsRequest
        typealias InnerResponse = FogLedger_GetOutputsResponse

        let client: FogLedger_FogMerkleProofAPIClient

        func call(
            request: Attest_Message,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<Attest_Message>) -> Void
        ) {
            let unaryCall = client.getOutputs(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}

extension FogLedger_FogMerkleProofAPIClient: AuthGrpcCallableClient {}
