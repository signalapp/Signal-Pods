//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable all

import Foundation
import SwiftProtobuf
#if canImport(LibMobileCoin)
import LibMobileCoin
#endif
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinHTTP
#endif

public protocol HttpRequester {
    func request(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<HTTPResponse, Error>) -> Void)
    
    func setFogTrustRoots(_ trustRoots: SecSSLCertificates?)
    func setConsensusTrustRoots(_ trustRoots: SecSSLCertificates?)
}

extension HttpRequester {
    public func setFogTrustRoots(_ trustRoots: SecSSLCertificates?) {
        logger.debug("setting fog trust roots not implemented")
    }
    public func setConsensusTrustRoots(_ trustRoots: SecSSLCertificates?) {
        logger.debug("setting consensus trust roots not implemented")
    }
}
