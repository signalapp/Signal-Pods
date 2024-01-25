//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct TxOutConfirmationNumber {
    let data32: Data32

    init(_ data: Data32) {
        self.data32 = data
    }
}

extension TxOutConfirmationNumber: DataConvertibleImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        guard let data32 = Data32(data.data) else {
            return nil
        }
        self.init(data32)
    }

    var data: Data { data32.data }
}

extension TxOutConfirmationNumber {
    init?(_ txOutConfirmationNumber: External_TxOutConfirmationNumber) {
        self.init(txOutConfirmationNumber.hash)
    }
}

extension External_TxOutConfirmationNumber {
    init(_ txOutConfirmationNumber: TxOutConfirmationNumber) {
        self.init()
        self.hash = txOutConfirmationNumber.data
    }
}
