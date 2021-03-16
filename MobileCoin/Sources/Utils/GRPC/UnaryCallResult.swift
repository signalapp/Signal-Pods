//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOHPACK

struct UnaryCallResult<ResponsePayload> {
    let status: GRPCStatus
    let initialMetadata: HPACKHeaders?
    let response: ResponsePayload?
    let trailingMetadata: HPACKHeaders?
}

extension UnaryResponseClientCall {
    var callResult: EventLoopFuture<UnaryCallResult<ResponsePayload>> {
        var resolvedInitialMetadata: HPACKHeaders?
        initialMetadata.whenSuccess { resolvedInitialMetadata = $0 }
        var resolvedResponse: ResponsePayload?
        response.whenSuccess { resolvedResponse = $0 }
        var resolvedTrailingMetadata: HPACKHeaders?
        trailingMetadata.whenSuccess { resolvedTrailingMetadata = $0 }

        return status.flatMap { status in
            self.eventLoop.makeSucceededFuture(
                UnaryCallResult(
                    status: status,
                    initialMetadata: resolvedInitialMetadata,
                    response: resolvedResponse,
                    trailingMetadata: resolvedTrailingMetadata))
        }
    }
}
