//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct TxOutConfirmationNumber {
    let data32: Data32

    init(_ data: Data32) {
        logger.info("")
        self.data32 = data
    }
}

extension TxOutConfirmationNumber: DataConvertibleImpl {
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

extension TxOutConfirmationNumber {
    init?(_ txOutConfirmationNumber: External_TxOutConfirmationNumber) {
        logger.info("")
        self.init(txOutConfirmationNumber.hash)
    }
}

extension External_TxOutConfirmationNumber {
    init(_ txOutConfirmationNumber: TxOutConfirmationNumber) {
        logger.info("")
        self.init()
        self.hash = txOutConfirmationNumber.data
    }
}
