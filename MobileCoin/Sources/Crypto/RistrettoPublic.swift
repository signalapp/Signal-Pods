//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct RistrettoPublic {
    let data32: Data32

    init?(_ data: Data32) {
        logger.info("")
        guard CryptoUtils.ristrettoPublicValidate(data.data) else {
            return nil
        }
        self.data32 = data
    }

    init(skippingValidation data: Data32) {
        logger.info("")
        self.data32 = data
    }
}

extension RistrettoPublic: DataConvertibleImpl {
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

extension RistrettoPublic {
    init?(_ ristrettoPublic: External_CompressedRistretto) {
        logger.info("")
        self.init(ristrettoPublic.data)
    }
}

extension External_CompressedRistretto {
    init(_ ristrettoPublic: RistrettoPublic) {
        logger.info("")
        self.init()
        self.data = ristrettoPublic.data
    }
}
