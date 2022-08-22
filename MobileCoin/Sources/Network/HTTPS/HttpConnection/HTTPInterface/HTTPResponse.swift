//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct HTTPResponse {
    let statusCode: Int
    let url: URL?
    let allHeaderFields: [AnyHashable: Any]
    let responseData: Data?

    public init(
        statusCode: Int,
        url: URL?,
        allHeaderFields: [AnyHashable: Any],
        responseData: Data?
    ) {
        self.statusCode = statusCode
        self.url = url
        self.allHeaderFields = allHeaderFields
        self.responseData = responseData
    }
}

extension HTTPResponse {
    public init(httpUrlResponse: HTTPURLResponse, responseData: Data?) {
        self.statusCode = httpUrlResponse.statusCode
        self.url = httpUrlResponse.url
        self.allHeaderFields = httpUrlResponse.allHeaderFields
        self.responseData = responseData
    }
}
