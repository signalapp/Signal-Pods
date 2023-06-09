//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct EmptyAttestedConnectionConfig: AttestedConnectionConfigProtocol {
    var url: MobileCoinUrlProtocol {
        logger.fatalError("Not implemented")
    }
    var transportProtocolOption: TransportProtocol.Option {
        logger.fatalError("Not implemented")
    }
    var trustRoots: [TransportProtocol: SSLCertificates] {
        logger.fatalError("Not implemented")
    }
    var authorization: BasicCredentials? {
        logger.fatalError("Not implemented")
    }
    var attestation: Attestation {
        logger.fatalError("Not implemented")
    }
}
