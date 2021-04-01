//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct RistrettoPrivate {
    let data32: Data32

    init?(_ data: Data32) {
        logger.info("")
        guard CryptoUtils.ristrettoPrivateValidate(data.data) else {
            return nil
        }
        self.data32 = data
    }

    init(skippingValidation data: Data32) {
        logger.info("")
        self.data32 = data
    }
}

extension RistrettoPrivate: DataConvertibleImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        logger.info("")
        guard let data32 = Data32(data.data) else {
            return nil
        }
        self.init(data32)
    }

    var data: Data { data32.data }
}

extension RistrettoPrivate {
    init?(_ ristrettoPrivate: External_RistrettoPrivate) {
        logger.info("")
        self.init(ristrettoPrivate.data)
    }
}

extension External_RistrettoPrivate {
    init(_ ristrettoPrivate: RistrettoPrivate) {
        logger.info("")
        self.init()
        self.data = ristrettoPrivate.data
    }
}
