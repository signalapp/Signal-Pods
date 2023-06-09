// swiftlint:disable:this file_name
//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

extension Mistyswap_ForgetOfframpRequest {

    static func make(offrampID: Data) -> Result<Self, InvalidInputError> {
        // Offramp ID should be 32 bytes
        guard Data32(offrampID) != nil else {
            return .failure(InvalidInputError("offrampID should be 32 bytes"))
        }
        var proto = Mistyswap_ForgetOfframpRequest()
        proto.offrampID = offrampID
        return .success(proto)
    }

}
