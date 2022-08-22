//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

class SecSSLCertificateValidator: SSLCertificateValidator {
    func validate(_ possibleCertificateData: [Data]) -> Result<SSLCertificates, InvalidInputError> {
        SecSSLCertificates.make(trustRootBytes: possibleCertificateData)
    }
}
