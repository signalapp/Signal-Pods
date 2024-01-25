//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct AddressHash {
    let data16: Data16

    var hex: String {
        data16.hexEncodedString()
    }

    init(_ data: Data16) {
        self.data16 = data
    }
}

extension AddressHash: DataConvertibleImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        guard let data16 = Data16(data.data) else {
            return nil
        }
        self.init(data16)
    }

    var data: Data { data16.data }
}

extension AddressHash: Equatable { }

extension AddressHash: Hashable { }

extension AddressHash: CustomStringConvertible {
    var description: String {
        hex
    }
}
