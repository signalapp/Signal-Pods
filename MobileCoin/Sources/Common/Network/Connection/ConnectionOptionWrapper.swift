//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

enum ConnectionOptionWrapper<GrpcService, HttpService> {
    case grpc(grpcService: GrpcService)
    case http(httpService: HttpService)
}
