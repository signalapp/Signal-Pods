//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import SwiftProtobuf

public protocol HTTPClientCall {
    /// The type of the request message for the call.
    associatedtype RequestPayload: SwiftProtobuf.Message

    /// The type of the response message for the call.
    associatedtype ResponsePayload: SwiftProtobuf.Message

    /// The resource path (generated)
    var path: String { get }

    /// The http method to use for the call
    var method: HTTPMethod { get }

    var requestPayload: RequestPayload? { get set }

    /// The response message returned from the service if the call is successful. This may be failed
    /// if the call encounters an error.
    ///
    /// Callers should rely on the `status` of the call for the canonical outcome.
    var responseType: ResponsePayload.Type { get set }

    /// The options used to make the session.
    var options: HTTPCallOptions? { get }

    /// Response metadata.
    var metadata: HTTPURLResponse? { get }

    /// Status of this call.
    ///
    var status: HTTPStatus? { get }
}
