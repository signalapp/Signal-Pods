//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public protocol SSLCertificates {
    var trustRootsBytes: [Data] { get }

    init?(trustRootBytes: [Data]) throws
}

extension SSLCertificates {
    init?(trustRootBytes: [Data]) {
        nil
    }

    public static func make(trustRootBytes: [Data]) -> Result<SSLCertificates, InvalidInputError> {
        do {
            let certificate = try Self(trustRootBytes: trustRootBytes)
            if let certificate = certificate {
                return .success(certificate)
            } else {
                return .failure(InvalidInputError("Unable to create NIOSSLCertificate"))
            }
        } catch {
            switch error {
            case let error as InvalidInputError:
                return .failure(error)
            default:
                return .failure(InvalidInputError("Unable to create NIOSSLCertificate"))
            }
        }
    }
}
