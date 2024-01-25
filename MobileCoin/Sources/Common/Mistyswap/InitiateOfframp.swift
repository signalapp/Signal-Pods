// swiftlint:disable:this file_name
// swiftlint:disable function_parameter_count
//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension MistyswapOfframp_InitiateOfframpRequest {
    static func make(
        mixinCredentialsJSON: String,
        srcAssetID: String,
        srcExpectedAmount: String,
        dstAssetID: String,
        dstAddress: String,
        dstAddressTag: String,
        minDstReceivedAmount: String,
        maxFeeAmountInDstTokens: String
    ) -> Result<Self, InvalidInputError> {
        JSONSerialization.verify(jsonString: mixinCredentialsJSON).map({ () in
            var proto = MistyswapOfframp_InitiateOfframpRequest()
            proto.mixinCredentialsJson = mixinCredentialsJSON

            var params = MistyswapOfframp_OfframpParams()
            params.srcAssetID = srcAssetID
            params.srcExpectedAmount = srcExpectedAmount
            params.dstAssetID = dstAssetID
            params.dstAddress = dstAddress
            params.dstAddressTag = dstAddressTag
            params.minDstReceivedAmount = minDstReceivedAmount
            params.maxFeeAmountInDstTokens = maxFeeAmountInDstTokens

            proto.params = params
            return proto
        })
    }
}
