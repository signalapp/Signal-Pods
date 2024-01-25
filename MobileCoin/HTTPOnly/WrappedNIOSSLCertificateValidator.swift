//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class WrappedNIOSSLCertificateValidator: SSLCertificateValidator {
    func validate(_ possibleCertificateData: [Data]) -> Result<SSLCertificates, InvalidInputError> {
        .failure(InvalidInputError("NIOSSLCertificates not supported with HTTP only target"))
    }
}
