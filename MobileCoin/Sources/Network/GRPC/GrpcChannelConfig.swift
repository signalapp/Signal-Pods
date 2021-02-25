//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

struct GrpcChannelConfig {
    let host: String
    let port: Int
    let useTls: Bool

    init(url: MobileCoinUrlProtocol) {
        self.host = url.host
        self.port = url.port
        self.useTls = url.useTls
    }
}

extension GrpcChannelConfig: Equatable {}
extension GrpcChannelConfig: Hashable {}
