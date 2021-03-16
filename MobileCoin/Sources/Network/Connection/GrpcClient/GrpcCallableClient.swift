//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC

protocol GrpcCallableClient: GrpcCallable {
    func call(request: Request, callOptions: CallOptions?) -> UnaryCall<Request, Response>
}

extension GrpcCallableClient {
    func call(
        request: Request,
        callOptions: CallOptions?,
        completion: @escaping (UnaryCallResult<Response>) -> Void
    ) {
        call(request: request, callOptions: callOptions).callResult.whenSuccess(completion)
    }
}
