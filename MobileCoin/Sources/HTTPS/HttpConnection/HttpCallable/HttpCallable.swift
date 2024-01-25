//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

public protocol HttpCallable {
    associatedtype Request
    associatedtype Response

    var requester: RestApiRequester { get }

    func call(
        request: Request,
        callOptions: HTTPCallOptions?,
        completion: @escaping (HttpCallResult<Response>) -> Void
    )
}

extension HttpCallable {
    func call(request: Request, completion: @escaping (HttpCallResult<Response>) -> Void) {
        call(request: request, callOptions: nil, completion: completion)
    }
}
