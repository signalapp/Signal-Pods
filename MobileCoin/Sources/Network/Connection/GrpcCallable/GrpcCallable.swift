//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import GRPC

protocol GrpcCallable {
    associatedtype Request
    associatedtype Response

    func call(
        request: Request,
        callOptions: CallOptions?,
        completion: @escaping (UnaryCallResult<Response>) -> Void)
}

extension GrpcCallable {
    func call(request: Request, completion: @escaping (UnaryCallResult<Response>) -> Void) {
        call(request: request, callOptions: nil, completion: completion)
    }
}
