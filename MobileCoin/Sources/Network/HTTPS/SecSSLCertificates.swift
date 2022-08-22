//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct SecSSLCertificates: SSLCertificates {
    public let trustRootsBytes: [Data]
    public let publicKeys: [SecKey]

    public init?(trustRootBytes bytes: [Data]) throws {
        switch Self.trustRoots(from: bytes) {
        case .success(let keys):
            self.publicKeys = keys
            self.trustRootsBytes = bytes
        case .failure(let error):
            throw error
        }
    }

    public static func trustRoots(from bytes: [Data]) -> Result<[SecKey], InvalidInputError> {
        Data.pinnedCertificateKeys(for: bytes).mapError {
            let errorMessage = "Error: \($0)"
            logger.error(errorMessage, logFunction: false)
            return InvalidInputError(errorMessage)
        }
    }
}
