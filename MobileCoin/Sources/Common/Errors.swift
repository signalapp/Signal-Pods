// swiftlint:disable:this file_name
// swiftlint:disable file_length
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

extension InvalidInputError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public enum BalanceUpdateError: Error {
    case connectionError(ConnectionError)
    case fogSyncError(FogSyncError)
}

extension BalanceUpdateError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension ConnectionError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension BalanceTransferEstimationFetcherError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension TransactionEstimationFetcherError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public enum SignedContingentInputCreationError: Error {
    case invalidInput(String)
    case insufficientBalance(String = String())
    case defragmentationRequired(String = String())
    case connectionError(ConnectionError)
    case requiresBlockVersion3(String)
}

extension SignedContingentInputCreationError {
    static func create(
        from transactionPreparationError: TransactionPreparationError
    ) -> SignedContingentInputCreationError {
        switch transactionPreparationError {
        case .invalidInput(let reason):
            return .invalidInput(reason)
        case .insufficientBalance(let reason):
            return .insufficientBalance(reason)
        case .defragmentationRequired(let reason):
            return .defragmentationRequired(reason)
        case .connectionError(let innerError):
            return .connectionError(innerError)
        }
    }

    static func create(
        from transactionInputSelectionError: TransactionInputSelectionError
    ) -> SignedContingentInputCreationError {
        switch transactionInputSelectionError {
        case .insufficientTxOuts(let reason):
            return .insufficientBalance(reason)
        case .defragmentationRequired(let reason):
            return .defragmentationRequired(reason)
        }
    }
}

extension SignedContingentInputCreationError: CustomStringConvertible {
    public var description: String {
        "SignedContingentInput creation error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .insufficientBalance(let reason):
                return "Insufficient balance\(!reason.isEmpty ? ": \(reason)" : "")"
            case .defragmentationRequired(let reason):
                return "Defragmentation required\(!reason.isEmpty ? ": \(reason)" : "")"
            case .connectionError(let innerError):
                return "\(innerError)"
            case .requiresBlockVersion3(let reason):
                return "Invalid block version: \(reason)"
            }
        }()
    }
}

extension SignedContingentInputCreationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public enum SignedContingentInputCancelationError: Error {
    case invalidSCI
    case inputError(String = String())
    case alreadySpent(String = String())
    case unownedTxOut(String = String())
    case connectionError(ConnectionError)
    case transactionPreparationError(TransactionPreparationError)
    case unknownError(String)
}

extension SignedContingentInputCancelationError: CustomStringConvertible {
    public var description: String {
        "SignedContingentInput cancelation error: " + {
            switch self {
            case .invalidSCI:
                return "Invalid signed contingent input"
            case .inputError(let reason):
                return "Input error\(!reason.isEmpty ? ": \(reason)" : "")"
            case .alreadySpent(let reason):
                return "Transaction for SCI already spent\(!reason.isEmpty ? ": \(reason)" : "")"
            case .unownedTxOut(let reason):
                return "The SCI txout is not owned by this account" +
                "\(!reason.isEmpty ? ": \(reason)" : "")"
            case .connectionError(let innerError):
                return "\(innerError)"
            case .transactionPreparationError(let innerError):
                return "\(innerError)"
            case .unknownError(let reason):
                return "Unknown Error: \(reason)"
            }
        }()
    }
}

extension SignedContingentInputCancelationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension TransactionPreparationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension DefragTransactionPreparationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public enum SCITransactionPreparationError: Error {
    case invalidInput(String)
    case insufficientBalance(String = String())
    case defragmentationRequired(String = String())
    case connectionError(ConnectionError)
    case requiresBlockVersion3(String = String())
}

extension SCITransactionPreparationError: CustomStringConvertible {
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
            case .requiresBlockVersion3(let reason):
                return "Invalid block version: \(reason)"
            }
        }()
    }
}

extension SCITransactionPreparationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension SubmitTransactionError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public enum TransactionSubmissionError: Error {
    case connectionError(ConnectionError)
    case invalidTransaction(String = String())
    case feeError(String = String())
    case tombstoneBlockTooFar(String = String())
    case missingMemo(String = String())
    case inputsAlreadySpent(String = String())
    case outputAlreadyExists(String = String())
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
            case .outputAlreadyExists(let reason):
                return "Output already exists\(!reason.isEmpty ? ": \(reason)" : "")"
            }
        }()
    }
}

extension TransactionSubmissionError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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
extension BalanceTransferEstimationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

@available(*, deprecated)
extension TransactionEstimationError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
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

extension SecurityError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public struct TimedOutError: Error {
}

extension TimedOutError: CustomStringConvertible {
    public var description: String {
        "Timed Out"
    }
}

extension TimedOutError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public struct SSLTrustError: Error {
    let reason: String

    init(_ reason: String) {
        self.reason = reason
    }
}

extension SSLTrustError: CustomStringConvertible {
    public var description: String {
        "SSL Trust Error: \(reason)"
    }
}

extension SSLTrustError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}

public enum MistyswapError: Error {
    case invalidInput(InvalidInputError)
    case connectionError(ConnectionError)
    case notInitialized(String)
}

extension MistyswapError: CustomStringConvertible {
    public var description: String {
        "Mistyswap error: " + {
            switch self {
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            case .connectionError(let innerError):
                return "\(innerError)"
            case .notInitialized(let description):
                return description
            }
        }()
    }
}

extension MistyswapError: LocalizedError {
    public var errorDescription: String? {
        "\(self)"
    }
}
