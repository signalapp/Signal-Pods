//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin

protocol AuthGrpcCallableClient: AttestableGrpcClient, AuthGrpcCallable {
    func auth(_ request: Attest_AuthMessage, callOptions: CallOptions?)
        -> UnaryCall<Attest_AuthMessage, Attest_AuthMessage>
}

extension AuthGrpcCallableClient {
    var authCallable: AuthGrpcCallable {
        self
    }
}

extension AuthGrpcCallableClient {
    func auth(
        _ request: Attest_AuthMessage,
        callOptions: CallOptions?,
        completion: @escaping (UnaryCallResult<Attest_AuthMessage>) -> Void
    ) {
        auth(request, callOptions: callOptions).callResult.whenSuccess(completion)
    }
}
