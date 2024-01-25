// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

protocol MistyswapService {
    func initiateOfframp(
        request: MistyswapOfframp_InitiateOfframpRequest,
        completion: @escaping (
            Result<MistyswapOfframp_InitiateOfframpResponse, ConnectionError>
        ) -> Void)

    func getOfframpStatus(
        request: MistyswapOfframp_GetOfframpStatusRequest,
        completion: @escaping (
            Result<MistyswapOfframp_GetOfframpStatusResponse, ConnectionError>
        ) -> Void)

    func forgetOfframp(
        request: MistyswapOfframp_ForgetOfframpRequest,
        completion: @escaping (
            Result<MistyswapOfframp_ForgetOfframpResponse, ConnectionError>
        ) -> Void)
}

protocol MistyswapServiceConnection: MistyswapService, ConnectionProtocol {}
