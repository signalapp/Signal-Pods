//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import SwiftProtobuf

/// A unary http call. The request is sent on initialization.
///
/// Note: while this object is a `struct`, its implementation delegates to `Call`. It therefore
/// has reference semantics.
public struct HTTPUnaryCall<
    RequestPayload: SwiftProtobuf.Message,
    ResponsePayload: SwiftProtobuf.Message
>: HTTPClientCall {
    public var path: String

    public var method: HTTPMethod = .POST

    public var response: ResponsePayload?

    /// The options used in the URLSession
    public var options: HTTPCallOptions?

    /// The initial metadata returned from the server.
    public var metadata: HTTPURLResponse?

    /// The request message sent to the server
    public var requestPayload: RequestPayload?

    /// The response returned by the server.
    public var responseType: ResponsePayload.Type
    public var responsePayload: ResponsePayload?

    /// The final status of the the RPC.
    public var status: HTTPStatus?
}
