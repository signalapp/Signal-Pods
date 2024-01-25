//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct LibMobileCoinError: Error {
    static func make(consuming error: UnsafeMutablePointer<McError>)
        -> Result<LibMobileCoinError, InvalidInputError>
    {
        defer {
            mc_error_free(error)
        }
        guard let libMcError = LibMobileCoinError(error.pointee) else {
            return .failure(InvalidInputError(
                "Unknown LibMobileCoin error code: \(error.pointee.error_code), description: " +
                "\(String(cString: error.pointee.error_description))"))
        }
        return .success(libMcError)
    }

    let errorCode: McErrorCode
    let description: String

    /// - Returns: `nil` when the error kind is unrecognized.
    init?(_ error: McError) {
        self.description = String(cString: error.error_description)

        guard let errorCode = McErrorCode(rawValue: error.error_code) else {
            return nil
        }
        self.errorCode = errorCode
    }
}
