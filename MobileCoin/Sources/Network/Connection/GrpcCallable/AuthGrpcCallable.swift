//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import GRPC
import LibMobileCoin

protocol AuthGrpcCallable {
    func auth(
        _ request: Attest_AuthMessage,
        callOptions: CallOptions?,
        completion: @escaping (UnaryCallResult<Attest_AuthMessage>) -> Void)
}

struct AuthGrpcCallableWrapper: GrpcCallable {
    let authCallable: AuthGrpcCallable

    func call(
        request: Attest_AuthMessage,
        callOptions: CallOptions?,
        completion: @escaping (UnaryCallResult<Attest_AuthMessage>) -> Void
    ) {
        authCallable.auth(request, callOptions: callOptions, completion: completion)
    }
}
