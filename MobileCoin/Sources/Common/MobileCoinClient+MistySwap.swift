//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable function_parameter_count

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension MobileCoinClient {

    public func initiateOfframp(
        mixinCredentialsJSON: String,
        srcAssetID: String,
        srcExpectedAmount: String,
        dstAssetID: String,
        dstAddress: String,
        dstAddressTag: String,
        minDstReceivedAmount: String,
        maxFeeAmountInDstTokens: String,
        _ completion: @escaping (Result<Data, MistyswapError>) -> Void
    ) {
        guard mistyswap.mistyswapServiceInitialized else {
            completion(.failure(.notInitialized("Mistyswap service not configured")))
            return
        }

        let result = MistyswapOfframp_InitiateOfframpRequest.make(
            mixinCredentialsJSON: mixinCredentialsJSON,
            srcAssetID: srcAssetID,
            srcExpectedAmount: srcExpectedAmount,
            dstAssetID: dstAssetID,
            dstAddress: dstAddress,
            dstAddressTag: dstAddressTag,
            minDstReceivedAmount: minDstReceivedAmount,
            maxFeeAmountInDstTokens: maxFeeAmountInDstTokens
        )
        .mapError { invalidInputError in
            MistyswapError.invalidInput(invalidInputError)
        }

        switch result {
        case .success(let proto):
            mistyswap.initiateOfframp(request: proto) { result in
                completion(
                    result.mapError { connectionError in
                        MistyswapError.connectionError(connectionError)
                    }
                    .map({ response in
                        response.serializedDataInfallible
                    })
                )
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    public func getOfframpStatus(
        offrampID: Data,
        _ completion: @escaping (Result<Data, MistyswapError>) -> Void
    ) {
        guard mistyswap.mistyswapServiceInitialized else {
            completion(.failure(.notInitialized("Mistyswap service not configured")))
            return
        }

        let result = MistyswapOfframp_GetOfframpStatusRequest.make(
            offrampID: offrampID
        )
        .mapError { invalidInputError in
            MistyswapError.invalidInput(invalidInputError)
        }

        switch result {
        case .success(let proto):
            mistyswap.getOfframpStatus(request: proto) { result in
                completion(
                    result.mapError { connectionError in
                        MistyswapError.connectionError(connectionError)
                    }
                    .map({ response in
                        response.serializedDataInfallible
                    })
                )
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    public func forgetOfframp(
        offrampID: Data,
        _ completion: @escaping (Result<Data, MistyswapError>) -> Void
    ) {
        guard mistyswap.mistyswapServiceInitialized else {
            completion(.failure(.notInitialized("Mistyswap service not configured")))
            return
        }

        let result = MistyswapOfframp_ForgetOfframpRequest.make(
            offrampID: offrampID
        )
        .mapError { invalidInputError in
            MistyswapError.invalidInput(invalidInputError)
        }

        switch result {
        case .success(let proto):
            mistyswap.forgetOfframp(request: proto) { result in
                completion(
                    result.mapError { connectionError in
                        MistyswapError.connectionError(connectionError)
                    }
                    .map({ response in
                        response.serializedDataInfallible
                    })
                )
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

}
