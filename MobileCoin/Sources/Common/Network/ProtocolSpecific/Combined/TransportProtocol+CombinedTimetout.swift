//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//
import Foundation

// Can import GRPC in SPM, and SPM only supports a GRPC+HTTP target, 
// So we support both if GRPC present.
#if canImport(LibMobileCoinGRPC)
extension TransportProtocol {
    static var grpcTimeout: Double = {
        guard let timeout = GrpcChannelManager.Defaults.callOptionsTimeLimit.timeout else {
            logger.error("No GrpcTimeout value !")
            return Double(0)
        }
        return Double(timeout.nanoseconds) / 1.0e9
    }()

    static var httpTimeout: Double = {
        DefaultHttpRequester.defaultConfiguration.timeoutIntervalForRequest
    }()

    var timeoutInSeconds: Double {
        switch self.option {
        case .grpc:
            return Self.grpcTimeout
        case .http:
            return Self.httpTimeout
        }
    }
}
#else

    #if canImport(LibMobileCoinHTTP)
    #else

        // Cannot import either SPM modules
        // Cocoapods version for Core (GRPC & HTTP)  & HTTP Only
        #if canImport(GRPC)
        // Cocoapods Core (GRPC + HTTP)
        extension TransportProtocol {
            static var grpcTimeout: Double = {
                guard let timeout = GrpcChannelManager.Defaults.callOptionsTimeLimit.timeout else {
                    logger.error("No GrpcTimeout value !")
                    return Double(0)
                }
                return Double(timeout.nanoseconds) / 1.0e9
            }()

            static var httpTimeout: Double = {
                DefaultHttpRequester.defaultConfiguration.timeoutIntervalForRequest
            }()

            var timeoutInSeconds: Double {
                switch self.option {
                case .grpc:
                    return Self.grpcTimeout
                case .http:
                    return Self.httpTimeout
                }
            }
        }
        #else
        // Cocoapods HTTP-Only
        extension TransportProtocol {
            static var grpcTimeout: Double = {
                0
            }()

            static var httpTimeout: Double = {
                DefaultHttpRequester.defaultConfiguration.timeoutIntervalForRequest
            }()

            var timeoutInSeconds: Double {
                switch self.option {
                case .grpc:
                    return Self.grpcTimeout
                case .http:
                    return Self.httpTimeout
                }
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
