//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import NIOSSL

protocol AttestedConnectionConfigProtocol: ConnectionConfigProtocol {
    var url: MobileCoinUrlProtocol { get }
    var attestation: Attestation { get }
    var trustRoots: [NIOSSLCertificate]? { get }
    var authorization: BasicCredentials? { get }
}

struct AttestedConnectionConfig<Url: MobileCoinUrlProtocol>: AttestedConnectionConfigProtocol {
    let urlTyped: Url
    let attestation: Attestation
    let trustRoots: [NIOSSLCertificate]?
    let authorization: BasicCredentials?

    init(
        url: Url,
        attestation: Attestation,
        trustRoots: [NIOSSLCertificate]?,
        authorization: BasicCredentials?
    ) {
        self.urlTyped = url
        self.attestation = attestation
        self.trustRoots = trustRoots
        self.authorization = authorization
    }

    var url: MobileCoinUrlProtocol { urlTyped }
}
