//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin
import NIOSSL

final class FogKeyImageConnection: AttestedConnection, FogKeyImageService {
    private let client: FogLedger_FogKeyImageAPIClient

    init(
        config: AttestedConnectionConfig<FogUrl>,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        let channel = channelManager.channel(for: config)
        self.client = FogLedger_FogKeyImageAPIClient(channel: channel)
        super.init(
            client: self.client,
            config: config,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func checkKeyImages(
        request: FogLedger_CheckKeyImagesRequest,
        completion: @escaping (Result<FogLedger_CheckKeyImagesResponse, ConnectionError>) -> Void
    ) {
        performAttestedCall(
            CheckKeyImagesCall(client: client),
            request: request,
            completion: completion)
    }
}

extension FogKeyImageConnection {
    private struct CheckKeyImagesCall: AttestedGrpcCallable {
        typealias InnerRequest = FogLedger_CheckKeyImagesRequest
        typealias InnerResponse = FogLedger_CheckKeyImagesResponse

        let client: FogLedger_FogKeyImageAPIClient

        func call(
            request: Attest_Message,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<Attest_Message>) -> Void
        ) {
            let unaryCall = client.checkKeyImages(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}

extension FogLedger_FogKeyImageAPIClient: AuthGrpcCallableClient {}
