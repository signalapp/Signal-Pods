//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIOSSL

protocol ConnectionConfigProtocol {
    var url: MobileCoinUrlProtocol { get }
    var trustRoots: [NIOSSLCertificate]? { get }
    var authorization: BasicCredentials? { get }
}

struct ConnectionConfig<Url: MobileCoinUrlProtocol>: ConnectionConfigProtocol {
    let urlTyped: Url
    let trustRoots: [NIOSSLCertificate]?
    let authorization: BasicCredentials?

    init(url: Url, trustRoots: [NIOSSLCertificate]?, authorization: BasicCredentials?) {
        self.urlTyped = url
        self.trustRoots = trustRoots
        self.authorization = authorization
    }

    var url: MobileCoinUrlProtocol { urlTyped }
}
