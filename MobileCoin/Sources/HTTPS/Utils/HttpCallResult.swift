//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

public struct HttpCallResult<ResponsePayload> {
    let error: Error?
    let status: HTTPStatus?
    let allHeaderFields: [AnyHashable: Any]?
    let response: ResponsePayload?

    init(
        error: Error? = nil,
        status: HTTPStatus? = nil,
        allHeaderFields: [AnyHashable: Any]? = nil,
        response: ResponsePayload? = nil
    ) {
        self.error = error
        self.status = status
        self.allHeaderFields = allHeaderFields
        self.response = response
    }
}
