// swiftlint:disable:this file_name

//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

public struct MalformedInput: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension MalformedInput: CustomStringConvertible {
    public var description: String {
        "Malformed input: \(reason)"
    }
}

public struct SerializationError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension SerializationError: CustomStringConvertible {
    public var description: String {
        "Serialization error: \(reason)"
    }
}

public struct InsufficientBalance: Error {
    let amountRequired: UInt64
    let currentBalance: Balance
}

extension InsufficientBalance: CustomStringConvertible {
    public var description: String {
        "Insufficient balance: amount required: \(amountRequired), current balance: " +
            "\(currentBalance)"
    }
}

public struct ConnectionFailure: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension ConnectionFailure: CustomStringConvertible {
    public var description: String {
        "Connection failure: \(reason)"
    }
}

public struct AuthorizationFailure: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension AuthorizationFailure: CustomStringConvertible {
    public var description: String {
        "Authorization failure: \(reason)"
    }
}

public struct InvalidReceipt: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension InvalidReceipt: CustomStringConvertible {
    public var description: String {
        "Invalid receipt error: \(reason)"
    }
}

public struct InternalError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension InternalError: CustomStringConvertible {
    public var description: String {
        "Internal error: \(reason)"
    }
}
