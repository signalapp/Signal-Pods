// swiftlint:disable:this file_name
//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension MistyswapOfframp_GetOfframpStatusRequest {

    static func make(offrampID: Data) -> Result<Self, InvalidInputError> {
        // Offramp ID should be 32 bytes
        guard Data32(offrampID) != nil else {
            return .failure(InvalidInputError(
                "offrampID should be 32 bytes, instead its \(offrampID.count)"))
        }
        var proto = MistyswapOfframp_GetOfframpStatusRequest()
        proto.offrampID = offrampID
        return .success(proto)
    }

}
