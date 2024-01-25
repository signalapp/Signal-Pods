//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// Encapsulates the result of a HTTP call.
public struct HTTPStatus {

    /// The REST status code
    public var code: Int

    /// The status message
    public var message: String?

    /// Whether the status is '.ok'.
    public var isOk: Bool {
        (200...299).contains(code)
    }

    /// The default status to return for succeeded calls.
    ///
    /// - Important: This should *not* be used when checking whether a returned status has an 'ok'
    ///   status code. Use `HTTPStatus.isOk` or check the code directly.
    public static let ok: HTTPStatus = .init(code: 200, message: "Success")

    /// "Internal server error" status.
    public static let processingError: HTTPStatus = .init(code: 500, message: "Error")
    
    public init(code: Int, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

extension HTTPStatus: CustomStringConvertible {
    public var description: String {
        codeDescription + (["", message].compactMap({ $0 }).joined(separator: " "))
    }

    private var codeDescription: String {
        switch code {
        case 200:
            return "Success: "
        case 400:
            return "Invalid Arguments: "
        case 403:
            return "Unauthorized: "
        case 404:
            return "Not Found: "
        case 500:
            return "Error: "
        case 501:
            return "Unimplemented: "
        case 503:
            return "Unavailable: "
        default:
            return "Unknown Error: "
        }
    }
}
