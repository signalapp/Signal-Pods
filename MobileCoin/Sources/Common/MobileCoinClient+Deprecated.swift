//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable function_default_parameter_at_end multiline_function_chains let_var_whitespace

import Foundation

extension MobileCoinClient {
    @available(*, deprecated, message:
        """
        Deprecated in favor of either :

        - `func accountActivity(for:TokenId)` which accepts a TokenId.
        - `var allAccountActivity` which returns all activity for all tokens

        `var accountActivity` will assume the default TokenId == .MOB // UInt64(0)

        Get a set of all tokenIds that are in TxOuts owned by this account with:

        `MobileCoinClient(...).accountTokenIds // Set<TokenId>`
        """)

    public var accountActivity: AccountActivity {
        accountActivity(for: .MOB)
    }

    @available(*, deprecated, message:
        """
        Deprecated in favor of `balance(for:TokenId)` which accepts a TokenId.
        `balance` will assume the default TokenId == .MOB // UInt64(0)

        Get a set of all tokenIds that are in TxOuts owned by this account with:

        `MobileCoinClient(...).accountTokenIds // Set<TokenId>`
        """)
    public var balance: Balance { balance(for: .MOB) }

    @available(*, deprecated, message:
        """
        Use the new `updateBalances(...)` that passes `Balances` into the completion closure.
        `Balances` is a new structure that holds multiple `Balance` structs for each known tokenId.

        ```
        public func updateBalances(
            completion: @escaping (Result<Balances, BalanceUpdateError>) -> Void
        )
        ```

        this function will return the `Balance` struct for the default TokenId == .MOB
        """)
    public func updateBalance(completion: @escaping (Result<Balance, ConnectionError>) -> Void) {
        updateBalances {
            completion($0.map({
                $0.mobBalance
            }).mapError({
                switch $0 {
                case .connectionError(let error):
                    return error
                case .fogSyncError(let error):
                    return ConnectionError.invalidServerResponse(error.description)
                }
            }))
        }
    }

    @available(*, deprecated, message:
        """
        Use the new `amountTransferable(...)` that accepts a `TokenId` as an input parameter.

        ```
        public func amountTransferable(
            tokenId: TokenId = .MOB
            feeLevel: FeeLevel = .minimum,
            completion: @escaping (Result<UInt64, BalanceTransferEstimationFetcherError>) -> Void
        )
        ```

        this function will return the amount transferable for the default TokenId == .MOB
        """)
    public func amountTransferable(
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<UInt64, BalanceTransferEstimationFetcherError>) -> Void
    ) {
        amountTransferable(tokenId: .MOB, feeLevel: feeLevel, completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the new `estimateTotalFee(...)` that accepts an `Amount` as an input parameter.

        ```
        public func estimateTotalFee(
            toSendAmount amount: Amount,
            feeLevel: FeeLevel = .minimum,
            completion: @escaping (Result<UInt64, TransactionEstimationFetcherError>) -> Void
        )
        ```

        this function will estimate the total fee assuming the default TokenId == .MOB
        """)
    public func estimateTotalFee(
        toSendAmount value: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<UInt64, TransactionEstimationFetcherError>) -> Void
    ) {
        estimateTotalFee(
            toSendAmount: Amount(value: value, tokenId: .MOB),
            feeLevel: feeLevel,
            completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the new `requiresDefragmentation(...)` that accepts an `Amount` as an input parameter.

        ```
        public func requiresDefragmentation(
            toSendAmount amount: Amount,
            feeLevel: FeeLevel = .minimum,
            completion: @escaping (Result<Bool, TransactionEstimationFetcherError>) -> Void
        )
        ```

        this function returns a Bool to the completion() assuming the default TokenId == .MOB
        """)
    public func requiresDefragmentation(
        toSendAmount value: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<Bool, TransactionEstimationFetcherError>) -> Void
    ) {
        requiresDefragmentation(
            toSendAmount: Amount(value: value, tokenId: .MOB),
            feeLevel: feeLevel,
            completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the new `prepareTransaction(...)` that accepts an `Amount` as an input parameter.

        ```
        public func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType = .unused,
            amount: Amount,
            fee: UInt64,
            completion: @escaping (
                Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
            ) -> Void
        )
        ```

        this function prepares a transaction assuming assuming the default TokenId == .MOB
        """)
    public func prepareTransaction(
        to recipient: PublicAddress,
        memoType: MemoType = .unused,
        amount value: UInt64,
        fee: UInt64,
        completion: @escaping (
            Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
        ) -> Void
    ) {
        prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: Amount(value: value, tokenId: .MOB),
            fee: fee) {
                completion($0.map({ ($0.transaction, $0.receipt) }))
        }

    }

    @available(*, deprecated, message:
        """
        Use the new `prepareTransaction(...)` that accepts an `Amount` as an input parameter.

        ```
        public func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType = .unused,
            amount: Amount,
            feeLevel: FeeLevel = .minimum,
            completion: @escaping (
                Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
            ) -> Void
        )
        ```

        this function prepares a transaction assuming assuming the default TokenId == .MOB
        """)
    public func prepareTransaction(
        to recipient: PublicAddress,
        memoType: MemoType = .unused,
        amount value: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (
            Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
        ) -> Void
    ) {
        prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: Amount(value: value, tokenId: .MOB),
            feeLevel: feeLevel) {
                completion($0.map { pending in
                    (pending.transaction, pending.receipt)
                })
        }
    }

    @available(*, deprecated, message:
        """
        Use the `prepareTransaction(...)` that accepts a MobileCoinRng instead of RngSeed

        ```
        public func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType = .recoverable,
            amount: Amount,
            fee: UInt64,
            rng: MobileCoinRng,
            completion: @escaping (
                Result<PendingSinglePayloadTransaction, TransactionPreparationError>
            ) -> Void
        ) {
        ```
        """)
    public func prepareTransaction(
        to recipient: PublicAddress,
        memoType: MemoType = .recoverable,
        amount: Amount,
        fee: UInt64,
        rngSeed: RngSeed,
        completion: @escaping (
            Result<PendingSinglePayloadTransaction, TransactionPreparationError>
        ) -> Void
    ) {
        prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: amount,
            fee: fee,
            rng: MobileCoinChaCha20Rng(rngSeed: rngSeed),
            completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the `prepareTransaction(...)` that accepts a MobileCoinRng instead of an RngSeed

        ```
        public func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType = .recoverable,
            amount: Amount,
            feeLevel: FeeLevel = .minimum,
            rng: MobileCoinRng,
            completion: @escaping (
                Result<PendingSinglePayloadTransaction, TransactionPreparationError>
            ) -> Void
        ) {
        ```

        this function creates a 32-byte seed by combining the data from 4 calls to rng.next()
        """)
    public func prepareTransaction(
        to recipient: PublicAddress,
        memoType: MemoType = .recoverable,
        amount: Amount,
        feeLevel: FeeLevel = .minimum,
        rngSeed: RngSeed,
        completion: @escaping (
            Result<PendingSinglePayloadTransaction, TransactionPreparationError>
        ) -> Void
    ) {
        prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: amount,
            feeLevel: feeLevel,
            rng: MobileCoinChaCha20Rng(rngSeed: rngSeed),
            completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the new `prepareDefragmentationStepTransactions(...)` that accepts an `Amount` as an
        input parameter.

        ```
        public func prepareDefragmentationStepTransactions(
            toSendAmount amount: Amount,
            recoverableMemo: Bool = false,
            feeLevel: FeeLevel = .minimum,
            completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
        )
        ```

        this function prepares transactions assuming assuming the default TokenId == .MOB
        """)
    public func prepareDefragmentationStepTransactions(
        toSendAmount value: UInt64,
        recoverableMemo: Bool = false,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
    ) {
        prepareDefragmentationStepTransactions(
            toSendAmount: Amount(value: value, tokenId: .MOB),
            recoverableMemo: false,
            feeLevel: feeLevel,
            completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the new `prepareDefragmentationStepTransactions(...)` that accepts a 32-byte rngSeed

        ```
        public func prepareDefragmentationStepTransactions(
            toSendAmount amount: Amount,
            recoverableMemo: Bool = false,
            feeLevel: FeeLevel = .minimum,
            rngSeed: RngSeed,
            completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
        ) {
        ```

        this function creates a 32-byte seed by combining the data from 4 calls to rng.next()
        """)
    public func prepareDefragmentationStepTransactions(
        toSendAmount value: UInt64,
        recoverableMemo: Bool = false,
        feeLevel: FeeLevel = .minimum,
        rng: MobileCoinRng,
        completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
    ) {
        guard let rngSeed = rng.generateRngSeed() else {
            completion(.failure(
                DefragTransactionPreparationError.invalidInput(
                    "Could not create 32-byte RNG seed")))
            return
        }
        prepareDefragmentationStepTransactions(
            toSendAmount: Amount(value: value, tokenId: .MOB),
            recoverableMemo: false,
            feeLevel: feeLevel,
            rngSeed: rngSeed,
            completion: completion)
    }

    @available(*, deprecated, message:
        """
        Use the new `submitTransaction(...)` which accepts a completion closure with a new result
        type with the success type being a UInt64 representing the conensus block height, and the
        failure type is a new error `SubmitTransactionError` which wraps the consensus block height
        and the existing `TransactionSubmissionError`. Consensus Block Height can be useful for
        querying fog to get information about the block your transaction landed in and/or when
        determining the "freshness"/"staleness" of an AccountActivitySnapshot.

        ```
        public func submitTransaction(
            transaction: Transaction,
            completion: @escaping (Result<UInt64, SubmitTransactionError>) -> Void
        )
        ```

        this function prepares transactions assuming assuming the default TokenId == .MOB
        """)
    public func submitTransaction(
        _ transaction: Transaction,
        completion: @escaping (Result<(), TransactionSubmissionError>) -> Void
    ) {
        // Wrap the new call, and map the success and error states for existing signature.
        submitTransaction(transaction: transaction) { result in
            completion(result.map({ _ in
                ()
            }).mapError({ submitTransactionError in
                submitTransactionError.submissionError
            }))
        }
    }

}

#if swift(>=5.5)

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension MobileCoinClient {
    @available(*, deprecated, message:
        """
        Use the `prepareTransaction(...)` that accepts a MobileCoinRng instead of an RngSeed

        ```
        public func prepareTransaction(
            to recipient: PublicAddress,
            memoType: MemoType = .recoverable,
            amount: Amount,
            feeLevel: FeeLevel = .minimum,
            rng: MobileCoinRng
        ) async ... {
        ```

        this function creates a 32-byte seed by combining the data from 4 calls to rng.next()
        """)
    public func prepareTransaction(
        to recipient: PublicAddress,
        amount: Amount,
        fee: UInt64,
        rngSeed: RngSeed,
        memoType: MemoType = .recoverable
    ) async throws -> PendingSinglePayloadTransaction {
        try await withCheckedThrowingContinuation { continuation in
            prepareTransaction(to: recipient,
                               memoType: memoType,
                               amount: amount,
                               fee: fee,
                               rngSeed: rngSeed) {
                continuation.resume(with: $0)
            }
        }
    }
}

#endif
