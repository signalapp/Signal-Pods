//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

#if swift(>=5.5)

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension MobileCoinClient {

    @discardableResult
    public func updateBalances() async throws -> Balances {
        try await withCheckedThrowingContinuation { continuation in
            updateBalances {
                continuation.resume(with: $0)
            }
        }
    }

    @discardableResult
    public func blockVersion() async throws -> BlockVersion {
        try await withCheckedThrowingContinuation { continuation in
            blockVersion {
                continuation.resume(with: $0)
            }
        }
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        amount: Amount,
        fee: UInt64,
        memoType: MemoType = .recoverable
    ) async throws -> PendingSinglePayloadTransaction {
        try await withCheckedThrowingContinuation { continuation in
            prepareTransaction(to: recipient,
                               memoType: memoType,
                               amount: amount,
                               fee: fee) {
                continuation.resume(with: $0)
            }
        }
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        amount: Amount,
        fee: UInt64,
        rng: MobileCoinRng,
        memoType: MemoType = .recoverable
    ) async throws -> PendingSinglePayloadTransaction {
        try await withCheckedThrowingContinuation { continuation in
            prepareTransaction(to: recipient,
                               memoType: memoType,
                               amount: amount,
                               fee: fee,
                               rng: rng) {
                continuation.resume(with: $0)
            }
        }
    }

    public func createSignedContingentInput(
        recipient: PublicAddress,
        amountToSend: Amount,
        amountToReceive: Amount
    ) async throws -> SignedContingentInput {
        try await withCheckedThrowingContinuation { continuation in
            createSignedContingentInput(
                recipient: recipient,
                amountToSend: amountToSend,
                amountToReceive: amountToReceive) {
                    continuation.resume(with: $0)
            }
        }
    }

    public func prepareCancelSignedContingentInputTransaction(
        signedContingentInput: SignedContingentInput,
        feeLevel: FeeLevel
    ) async throws -> PendingSinglePayloadTransaction
    {
        try await withCheckedThrowingContinuation { continuation in
            prepareCancelSignedContingentInputTransaction(
                    signedContingentInput: signedContingentInput,
                    feeLevel: feeLevel) {
                continuation.resume(with: $0)
            }
        }
    }

    public func prepareTransaction(
        presignedInput: SignedContingentInput,
        feeLevel: FeeLevel = .minimum
    ) async throws -> PendingTransaction {
        try await withCheckedThrowingContinuation { continuation in
            prepareTransaction(presignedInput: presignedInput,
                               feeLevel: feeLevel) {
                continuation.resume(with: $0)
            }
        }
    }

    @discardableResult
    public func submitTransaction(
        transaction: Transaction
    ) async throws -> UInt64 {
        try await withCheckedThrowingContinuation { continuation in
            submitTransaction(transaction: transaction) {
                continuation.resume(with: $0)
            }
        }
    }

    public func amountTransferable(
        tokenId: TokenId,
        feeLevel: FeeLevel = .minimum
    ) async throws -> UInt64 {
        try await withCheckedThrowingContinuation { continuation in
            amountTransferable(tokenId: tokenId,
                               feeLevel: feeLevel) {
                continuation.resume(with: $0)
            }
        }
    }

    public func estimateTotalFee(
        toSendAmount amount: Amount,
        feeLevel: FeeLevel = .minimum
    ) async throws -> UInt64 {
        try await withCheckedThrowingContinuation { continuation in
            estimateTotalFee(toSendAmount: amount,
                             feeLevel: feeLevel) {
                continuation.resume(with: $0)
            }
        }
    }

    public func status(
        of transaction: Transaction
    ) async throws -> TransactionStatus {
        try await withCheckedThrowingContinuation { continuation in
            status(of: transaction) {
                continuation.resume(with: $0)
            }
        }
    }

    public func txOutStatus(
        of transaction: Transaction
    ) async throws -> TransactionStatus {
        try await withCheckedThrowingContinuation { continuation in
            txOutStatus(of: transaction) {
                continuation.resume(with: $0)
            }
        }
    }

}

#endif
