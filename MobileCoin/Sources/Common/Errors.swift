// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
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

public enum BalanceUpdateError: Error {
    case connectionError(ConnectionError)
    case fogSyncError(FogSyncError)
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

public enum BalanceTransferEstimationFetcherError: Error {
    case feeExceedsBalance(String = String())
    case balanceOverflow(String = String())
    case connectionError(ConnectionError)
}

extension BalanceTransferEstimationFetcherError: CustomStringConvertible {
    public var description: String {
        "Balance transfer estimation error: " + {
            switch self {
            case .feeExceedsBalance(let reason):
                return "Fee exceeds balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .balanceOverflow(let reason):
                return "Balance overflow\(!reason.isEmpty ? ": \(reason)" : "")"
            case .connectionError(let innerError):
                return "\(innerError)"
            }
        }()
    }
}

public enum TransactionEstimationFetcherError: Error {
    case invalidInput(String)
    case insufficientBalance(String = String())
    case connectionError(ConnectionError)
}

extension TransactionEstimationFetcherError: CustomStringConvertible {
    public var description: String {
        "Transaction estimation error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .insufficientBalance(let reason):
                return "Insufficient balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .connectionError(let innerError):
                return "\(innerError)"
            }
        }()
    }
}

public enum TransactionPreparationError: Error {
    case invalidInput(String)
    case insufficientBalance(String = String())
    case defragmentationRequired(String = String())
    case connectionError(ConnectionError)
}

extension TransactionPreparationError: CustomStringConvertible {
    public var description: String {
        "Transaction preparation error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .insufficientBalance(let reason):
                return "Insufficient balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .defragmentationRequired(let reason):
                return "Defragmentation required\(!reason.isEmpty ? ": \(reason)" : "")"
            case .connectionError(let innerError):
                return "\(innerError)"
            }
        }()
    }
}

public enum DefragTransactionPreparationError: Error {
    case invalidInput(String)
    case insufficientBalance(String = String())
    case connectionError(ConnectionError)
}

extension DefragTransactionPreparationError: CustomStringConvertible {
    public var description: String {
        "Defragmentation transaction preparation error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .insufficientBalance(let reason):
                return "Insufficient balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .connectionError(let innerError):
                return "\(innerError)"
            }
        }()
    }
}

public struct SubmitTransactionError: Error {
    public let submissionError: TransactionSubmissionError
    public let consensusBlockCount: UInt64?
}

extension SubmitTransactionError: CustomStringConvertible {
    public var description: String {
        "Submit Transaction Error: " +
        "Consensus Block Count == \(consensusBlockCount?.description ?? "nil"), " +
        "\(submissionError)"
    }
}

public enum TransactionSubmissionError: Error {
    case connectionError(ConnectionError)
    case invalidTransaction(String = String())
    case feeError(String = String())
    case tombstoneBlockTooFar(String = String())
    case missingMemo(String = String())
    case inputsAlreadySpent(String = String())
}

extension TransactionSubmissionError: CustomStringConvertible {
    public var description: String {
        "Transaction submission error: " + {
            switch self {
            case .connectionError(let connectionError):
                return "\(connectionError)"
            case .missingMemo(let reason):
                return "Missing memo error\(!reason.isEmpty ? ": \(reason)" : "")"
            case .feeError(let reason):
                return "Fee error\(!reason.isEmpty ? ": \(reason)" : "")"
            case .invalidTransaction(let reason):
                return "Invalid transaction\(!reason.isEmpty ? ": \(reason)" : "")"
            case .tombstoneBlockTooFar(let reason):
                return "Tombstone block too far\(!reason.isEmpty ? ": \(reason)" : "")"
            case .inputsAlreadySpent(let reason):
                return "Inputs already spent\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

@available(*, deprecated)
public enum BalanceTransferEstimationError: Error {
    case feeExceedsBalance(String = String())
    case balanceOverflow(String = String())
}

@available(*, deprecated)
extension BalanceTransferEstimationError: CustomStringConvertible {
    public var description: String {
        "Balance transfer estimation error: " + {
            switch self {
            case .feeExceedsBalance(let reason):
                return "Fee exceeds balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .balanceOverflow(let reason):
                return "Balance overflow\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

@available(*, deprecated)
public enum TransactionEstimationError: Error {
    case invalidInput(String)
    case insufficientBalance(String = String())
}

@available(*, deprecated)
extension TransactionEstimationError: CustomStringConvertible {
    public var description: String {
        "Transaction estimation error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .insufficientBalance(let reason):
                return "Insufficient balance\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

public struct SecurityError: Error {
    let status: OSStatus?
    let message: String?

    init(_ status: OSStatus? = nil, message: String? = nil) {
        self.status = status
        self.message = message
    }
}

extension SecurityError: CustomStringConvertible {
    static var nilPublicKey = """
        the public key could not be extracted \
        (this can happen if the public key algorithm is not supported).
    """

    public var description: String {
        guard let osstatus = status else { return "Security Error Code - \(message ?? "Unknown")" }
        if #available(iOS 11.3, *) {
            return "Security Error Code - \(osstatus): " +
                   "\(SecCopyErrorMessageString(osstatus, nil) ?? "Unknown" as CFString)"
        } else {
            return "Security Error Code - \(osstatus) ... see Apple Security Framework SecBase.h"
        }
    }
}
