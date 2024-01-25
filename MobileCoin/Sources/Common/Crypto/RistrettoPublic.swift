//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct RistrettoPublic {
    let data32: Data32

    init?(_ data: Data32) {
        guard CryptoUtils.ristrettoPublicValidate(data.data) else {
            return nil
        }
        self.data32 = data
    }

    init(skippingValidation data: Data32) {
        self.data32 = data
    }
}

extension RistrettoPublic: DataConvertibleImpl {
    typealias Iterator = Data.Iterator

    init?(_ data: Data) {
        guard let data32 = Data32(data.data) else {
            return nil
        }
        self.init(data32)
    }

    var data: Data { data32.data }
}

extension RistrettoPublic {
    init?(_ ristrettoPublic: External_CompressedRistretto) {
        self.init(ristrettoPublic.data)
    }
}

extension External_CompressedRistretto {
    init(_ ristrettoPublic: RistrettoPublic) {
        self.init()
        self.data = ristrettoPublic.data
    }
}

public struct WrappedRistrettoPublic: Hashable {
    let ristretto: RistrettoPublic

    public init?(_ data: Data) {
        guard
            let data32 = Data32(data.data),
            let ristretto = RistrettoPublic(data32)
        else {
            return nil
        }
        self.ristretto = ristretto
    }

    public var data: Data { ristretto.data }
}
