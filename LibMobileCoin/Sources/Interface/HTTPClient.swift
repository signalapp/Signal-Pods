//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import SwiftProtobuf

/// A HTTP client.
public protocol HTTPClient {
    /// The call options to use should the user not provide per-call options.
    var defaultHTTPCallOptions: HTTPCallOptions { get set }
}

extension HTTPClient {
    public func makeUnaryCall<Request, Response>(
        path: String,
        request: Request,
        callOptions: HTTPCallOptions? = nil,
        responseType: Response.Type = Response.self
    ) -> HTTPUnaryCall<
            Request,
            Response
        > where Request: SwiftProtobuf.Message, Response: SwiftProtobuf.Message
    {
        HTTPUnaryCall(
                path: path,
                options: callOptions,
                requestPayload: request,
                responseType: responseType)
    }
}
