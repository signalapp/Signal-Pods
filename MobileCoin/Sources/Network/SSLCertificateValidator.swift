//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol SSLCertificateValidator {
    func validate(_ certificateData: [Data]) -> Result<SSLCertificates, InvalidInputError>
}
