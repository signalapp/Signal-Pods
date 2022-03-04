//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class WrappedNIOSSLCertificateValidator : SSLCertificateValidator {
    func validate(_ possibleCertificateData: [Data]) -> Result<SSLCertificates, InvalidInputError> {
        return .failure(InvalidInputError("NIOSSLCertificates not supported with HTTP only target"))
    }
}
