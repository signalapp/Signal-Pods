//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct RistrettoPrivate {
    let data32: Data32

    init?(_ data: Data32) {
        guard CryptoUtils.ristrettoPrivateValidate(data.data) else {
            return nil
        }
        self.data32 = data
    }

    init(skippingValidation data: Data32) {
        self.data32 = data
    }
}

extension RistrettoPrivate: DataConvertibleImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        guard let data32 = Data32(data.data) else {
            return nil
        }
        self.init(data32)
    }

    var data: Data { data32.data }
}

extension RistrettoPrivate {
    init?(_ ristrettoPrivate: External_RistrettoPrivate) {
        self.init(ristrettoPrivate.data)
    }
}

extension External_RistrettoPrivate {
    init(_ ristrettoPrivate: RistrettoPrivate) {
        self.init()
        self.data = ristrettoPrivate.data
    }
}

public struct WrappedRistrettoPrivate: Hashable {
    let ristretto: RistrettoPrivate

    public init?(_ data: Data) {
        guard
            let data32 = Data32(data.data),
            let ristretto = RistrettoPrivate(data32)
        else {
            return nil
        }
        self.ristretto = ristretto
    }

    public var data: Data { ristretto.data }
}
