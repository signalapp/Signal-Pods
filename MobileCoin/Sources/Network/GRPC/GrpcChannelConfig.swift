//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIOSSL

struct GrpcChannelConfig {
    let host: String
    let port: Int
    let useTls: Bool
    let trustRoots: [NIOSSLCertificate]?

    init(url: MobileCoinUrlProtocol, trustRoots: [NIOSSLCertificate]? = nil) {
        self.host = url.host
        self.port = url.port
        self.useTls = url.useTls
        self.trustRoots = trustRoots
    }
}

extension GrpcChannelConfig: Equatable {}
extension GrpcChannelConfig: Hashable {}
