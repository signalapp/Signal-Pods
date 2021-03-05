// swiftlint:disable:this file_name

//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

public struct InvalidInputError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension InvalidInputError: CustomStringConvertible {
    public var description: String {
        "Invalid input: \(reason)"
    }
}

public enum ConnectionError: Error {
    case connectionFailure(String)
    case authorizationFailure(String)
    case invalidServerResponse(String)
    case attestationVerificationFailed(String)
    case outdatedClient(String)
    case serverRateLimited(String)
}

extension ConnectionError: CustomStringConvertible {
    public var description: String {
        "Connection error: " + {
            switch self {
            case .connectionFailure(let reason):
                return "Connection failure: \(reason)"
            case .authorizationFailure(let reason):
                return "Authorization failure: \(reason)"
            case .invalidServerResponse(let reason):
                return "Invalid server response: \(reason)"
            case .attestationVerificationFailed(let reason):
                return "Attestation verification failed: \(reason)"
            case .outdatedClient(let reason):
                return "Outdated client: \(reason)"
            case .serverRateLimited(let reason):
                return "Server rate limited: \(reason)"
            }
        }()
    }
}

@available(*, deprecated, renamed: "InvalidInputError")
public typealias MalformedInput = InvalidInputError

@available(*, deprecated)
public struct SerializationError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

@available(*, deprecated)
extension SerializationError: CustomStringConvertible {
    public var description: String {
        "Serialization error: \(reason)"
    }
}

@available(*, deprecated)
public struct InsufficientBalance: Error {
    let amountRequired: UInt64
    let currentBalance: Balance
}

@available(*, deprecated)
extension InsufficientBalance: CustomStringConvertible {
    public var description: String {
        "Insufficient balance: amount required: \(amountRequired), current balance: " +
            "\(currentBalance)"
    }
}

@available(*, deprecated)
public struct ConnectionFailure: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

@available(*, deprecated)
extension ConnectionFailure: CustomStringConvertible {
    public var description: String {
        "Connection failure: \(reason)"
    }
}

@available(*, deprecated)
public struct AuthorizationFailure: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

@available(*, deprecated)
extension AuthorizationFailure: CustomStringConvertible {
    public var description: String {
        "Authorization failure: \(reason)"
    }
}

@available(*, deprecated)
public struct InvalidReceipt: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

@available(*, deprecated)
extension InvalidReceipt: CustomStringConvertible {
    public var description: String {
        "Invalid receipt error: \(reason)"
    }
}

@available(*, deprecated)
public struct InternalError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

@available(*, deprecated)
extension InternalError: CustomStringConvertible {
    public var description: String {
        "Internal error: \(reason)"
    }
}
