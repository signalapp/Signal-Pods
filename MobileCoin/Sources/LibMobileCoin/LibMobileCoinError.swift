//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct LibMobileCoinError: Error {
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

    init(consuming error: UnsafeMutablePointer<McError>) {
        defer {
            mc_error_free(error)
        }
        guard let libMcError = Self(error.pointee) else {
            fatalError("Error: \(Self.self).\(#function): unknown error code: " +
                "\(error.pointee.error_code), description: " +
                "\(String(cString: error.pointee.error_description))")
        }
        self = libMcError
    }
}
