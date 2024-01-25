//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

// Can import GRPC in SPM, and SPM only supports a GRPC+HTTP target, 
// So we support both if GRPC present.
#if canImport(LibMobileCoinGRPC)
extension TransportProtocol: SupportedProtocols {
    public static var supportedProtocols: [TransportProtocol] {
        [.grpc, .http]
    }
}
#else

    #if canImport(LibMobileCoinHTTP)
    #else

        // Cannot import either SPM modules
        // Cocoapods version for Core (GRPC & HTTP)  & HTTP Only
        #if canImport(GRPC)
        extension TransportProtocol: SupportedProtocols {
            public static var supportedProtocols: [TransportProtocol] {
                [.grpc, .http]
            }
        }
        #else
        extension TransportProtocol: SupportedProtocols {
            public static var supportedProtocols: [TransportProtocol] {
                [.http]
            }
        }
        #endif

    #endif

#endif

    // GRPC-Only
    // Cannot import HTTP, can import GRPC == GRPC-only
    #if canImport(LibMobileCoinHTTP)
    #else

    #if canImport(LibMobileCoinGRPC)
    #else
    #endif

#endif
