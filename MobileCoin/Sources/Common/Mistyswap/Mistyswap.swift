//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct Mistyswap: MistyswapService {
    private let mistyswap: MistyswapService?

    var mistyswapServiceInitialized: Bool {
        mistyswap != nil
    }

    init(
        mistyswap: MistyswapService?
    ) {
        self.mistyswap = mistyswap
    }

    func initiateOfframp(
        request: MistyswapOfframp_InitiateOfframpRequest,
        completion: @escaping (
            Result<MistyswapOfframp_InitiateOfframpResponse, ConnectionError>
        ) -> Void
    ) {
        mistyswap?.initiateOfframp(request: request, completion: completion)
    }

    func getOfframpStatus(
        request: MistyswapOfframp_GetOfframpStatusRequest,
        completion: @escaping (
            Result<MistyswapOfframp_GetOfframpStatusResponse, ConnectionError>
        ) -> Void
    ) {
        mistyswap?.getOfframpStatus(request: request, completion: completion)
    }

    func forgetOfframp(
        request: MistyswapOfframp_ForgetOfframpRequest,
        completion: @escaping (
            Result<MistyswapOfframp_ForgetOfframpResponse, ConnectionError>
        ) -> Void
    ) {
        mistyswap?.forgetOfframp(request: request, completion: completion)
    }
}

public enum MixinAssetID: String {
    case MOB = "eea900a8-b327-488c-8d8d-1428702fe240"
    case EUSD = "659c407a-0489-30bf-9e6f-84ef25c971c9"
    case USDC = "9b180ab6-6abe-3dc0-a13f-04169eb34bfa"
    case ETH = "43d61dcd-e413-450d-80b8-101d5e903357"
    case MATIC = "b7938396-3f94-4e0a-9179-d3440718156f"
    case USDC_POLYGON = "80b65786-7c75-3523-bc03-fb25378eae41"
    case TRX_TRON = "25dabac5-056a-48ff-b9f9-f67395dc407c"
    case USDT_TRON = "b91e18ff-a9ae-3dc7-8679-e935d9a4b34b"
}

extension MixinAssetID: CustomStringConvertible {
    public var description: String {
        switch self {
        case .MOB:
            return "MOB"
        case .EUSD:
            return "eUSD"
        case .USDC:
            return "USDC"
        case .ETH:
            return "ETH"
        case .MATIC:
            return "MATIC"
        case .USDC_POLYGON:
            return "USDC-Poly"
        case .TRX_TRON:
            return "TRX"
        case .USDT_TRON:
            return "USDT-Tron"
        }
    }
}
