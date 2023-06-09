//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains
// swiftlint:disable function_default_parameter_at_end type_body_length file_length

import Foundation

public final class MobileCoinClient {
    /// - Returns: `InvalidInputError` when `accountKey` isn't configured to use Fog.
    public static func make(accountKey: AccountKey, config: Config)
        -> Result<MobileCoinClient, InvalidInputError>
    {
        guard let accountKey = AccountKeyWithFog(accountKey: accountKey) else {
            let errorMessage = "Accounts without fog URLs are not currently supported."
            logger.error(errorMessage, logFunction: false)
            return .failure(InvalidInputError(errorMessage))
        }

        return .success(MobileCoinClient(accountKey: accountKey, config: config))
    }

    private let accountLock: ReadWriteDispatchLock<Account>
    private let serialQueue: DispatchQueue
    private let callbackQueue: DispatchQueue

    private let txOutSelectionStrategy: TxOutSelectionStrategy
    private let mixinSelectionStrategy: MixinSelectionStrategy
    private let fogQueryScalingStrategy: FogQueryScalingStrategy

    private let serviceProvider: ServiceProvider
    private let fogResolverManager: FogResolverManager
    private let metaFetcher: BlockchainMetaFetcher

    private let defaultRng = MobileCoinDefaultRng()
    private let fogSyncChecker: FogSyncCheckable

    let mistyswap: Mistyswap

    static let latestBlockVersion = BlockVersion.legacy

    init(accountKey: AccountKeyWithFog, config: Config) {
        logger.info("""
            Initializing \(Self.self):
            \(Self.configDescription(accountKey: accountKey, config: config))
            """, logFunction: false)

        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)")
        self.callbackQueue = config.callbackQueue ?? DispatchQueue.main
        self.fogSyncChecker = config.fogSyncCheckable
        self.accountLock = .init(Account(accountKey: accountKey, syncChecker: fogSyncChecker))
        self.txOutSelectionStrategy = config.txOutSelectionStrategy
        self.mixinSelectionStrategy = config.mixinSelectionStrategy
        self.fogQueryScalingStrategy = config.fogQueryScalingStrategy

        let grpcFactory = GrpcProtocolConnectionFactory()
        let httpFactory = HttpProtocolConnectionFactory(
            httpRequester: config.networkConfig.httpRequester)

        self.serviceProvider = DefaultServiceProvider(
            networkConfig: config.networkConfig,
            targetQueue: serialQueue,
            grpcConnectionFactory: grpcFactory,
            httpConnectionFactory: httpFactory)

        self.fogResolverManager = FogResolverManager(
            fogReportAttestation: config.networkConfig.fogReportAttestation,
            serviceProvider: serviceProvider,
            targetQueue: serialQueue)

        self.metaFetcher = BlockchainMetaFetcher(
            blockchainService: serviceProvider.blockchainService,
            metaCacheTTL: config.metaCacheTTL,
            targetQueue: serialQueue)

        self.mistyswap = Mistyswap(
            mistyswap: serviceProvider.mistyswapService
        )
    }

    public var balances: Balances {
        accountLock.readSync { $0.cachedBalances }
    }

    public var accountTokenIds: Set<TokenId> {
        accountLock.readSync { $0.cachedTxOutTokenIds }
    }

    public func recoverTransactions<Contact: PublicAddressProvider>(
        contacts: Set<Contact>
    ) -> [HistoricalTransaction] where Contact: Hashable {
        recoverTransactions(allAccountActivity().txOuts, contacts: contacts)
    }

    public func recoverContactTransactions<Contact: PublicAddressProvider>(
        contact: Contact
    ) -> [HistoricalTransaction] where Contact: Hashable {
        recoverTransactions(contacts: Set([contact]))
    }

    public func recoverTransactions<Contact: PublicAddressProvider>(
        _ transactions: Set<OwnedTxOut>,
        contacts: Set<Contact>
    ) -> [HistoricalTransaction] where Contact: Hashable {
        Self.recoverTransactions(transactions, contacts: contacts)
    }

    public func recoverContactTransactions<Contact: PublicAddressProvider>(
        _ transactions: Set<OwnedTxOut>,
        contact: Contact
    ) -> [HistoricalTransaction] where Contact: Hashable {
        recoverTransactions(transactions, contacts: Set([contact]))
    }

    public func allAccountActivity() -> AccountActivity {
        accountLock.readSync { $0.allCachedAccountActivity }
    }

    public func accountActivity(for tokenId: TokenId) -> AccountActivity {
        accountLock.readSync { $0.cachedAccountActivity(for: tokenId) }
    }

    public func balance(for tokenId: TokenId = .MOB) -> Balance {
        accountLock.readSync { $0.cachedBalance(for: tokenId) }
    }

    public func setTransportProtocol(_ transportProtocol: TransportProtocol) {
        serviceProvider.setTransportProtocolOption(transportProtocol.option)
    }

    public func setConsensusBasicAuthorization(username: String, password: String) {
        let credentials = BasicCredentials(username: username, password: password)
        serviceProvider.setConsensusAuthorization(credentials: credentials)
    }

    public func setFogBasicAuthorization(username: String, password: String) {
        let credentials = BasicCredentials(username: username, password: password)
        serviceProvider.setFogUserAuthorization(credentials: credentials)
    }

    public func updateBalances(
        completion: @escaping (Result<Balances, BalanceUpdateError>) -> Void
    ) {
        Account.BalanceUpdater(
            account: accountLock,
            fogViewService: serviceProvider.fogViewService,
            fogKeyImageService: serviceProvider.fogKeyImageService,
            fogBlockService: serviceProvider.fogBlockService,
            fogQueryScalingStrategy: fogQueryScalingStrategy,
            targetQueue: serialQueue
        ).updateBalances { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func amountTransferable(
        tokenId: TokenId,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<UInt64, BalanceTransferEstimationFetcherError>) -> Void
    ) {
        Account.TransactionEstimator(
            account: accountLock,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).amountTransferable(tokenId: tokenId, feeLevel: feeLevel, completion: completion)
    }

    public func estimateTotalFee(
        toSendAmount amount: Amount,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<UInt64, TransactionEstimationFetcherError>) -> Void
    ) {
        Account.TransactionEstimator(
            account: accountLock,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).estimateTotalFee(toSendAmount: amount, feeLevel: feeLevel, completion: completion)
    }

    public func requiresDefragmentation(
        toSendAmount amount: Amount,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<Bool, TransactionEstimationFetcherError>) -> Void
    ) {
        Account.TransactionEstimator(
            account: accountLock,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).requiresDefragmentation(toSendAmount: amount, feeLevel: feeLevel, completion: completion)
    }

    public func createSignedContingentInput(
        recipient: PublicAddress,
        amountToSend: Amount,
        amountToReceive: Amount,
        completion: @escaping (
            Result<SignedContingentInput, SignedContingentInputCreationError>
        ) -> Void
    ) {
        guard let rngSeed = defaultRng.generateRngSeed() else {
            completion(.failure(
                SignedContingentInputCreationError.invalidInput("Couldn't create 32byte RNG seed")))
            return
        }
        Account.SCIOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).createSignedContingentInput(
            to: recipient,
            memoType: .unused,
            amountToSend: amountToSend,
            amountToReceive: amountToReceive
        ) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func prepareCancelSignedContingentInputTransaction(
        signedContingentInput: SignedContingentInput,
        feeLevel: FeeLevel,
        completion: @escaping (
            Result<PendingSinglePayloadTransaction, SignedContingentInputCancelationError>
        ) -> Void
    ) {
        guard let rngSeed = defaultRng.generateRngSeed() else {
            completion(.failure(SignedContingentInputCancelationError.unknownError(
                "Couldn't create 32byte RNG seed")))
            return
        }
        Account.SCIOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).prepareCancelSignedContingentInputTransaction(
            signedContingentInput: signedContingentInput,
            feeLevel: feeLevel
        ) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        memoType: MemoType = .recoverable,
        amount: Amount,
        fee: UInt64,
        completion: @escaping (
            Result<PendingSinglePayloadTransaction, TransactionPreparationError>
        ) -> Void
    ) {
        prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: amount,
            fee: fee,
            rng: MobileCoinChaCha20Rng(),
            completion: completion)
    }

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
        guard let rngSeed = rng.generateRngSeed() else {
            completion(.failure(
                TransactionPreparationError.invalidInput("Could not create 32 byte RNG seed")))
            return
        }
        Account.TransactionOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: amount,
            fee: fee
        ) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        memoType: MemoType = .recoverable,
        amount: Amount,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (
            Result<PendingSinglePayloadTransaction, TransactionPreparationError>
        ) -> Void
    ) {
        prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: amount,
            feeLevel: feeLevel,
            rng: MobileCoinChaCha20Rng(),
            completion: completion)
    }

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
        guard let rngSeed = rng.generateRngSeed() else {
            completion(.failure(
                TransactionPreparationError.invalidInput("Could not create 32-byte RNG seed")))
            return
        }
        Account.TransactionOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).prepareTransaction(
            to: recipient,
            memoType: memoType,
            amount: amount,
            feeLevel: feeLevel
        ) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func prepareDefragmentationStepTransactions(
        toSendAmount amount: Amount,
        recoverableMemo: Bool = false,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
    ) {
        prepareDefragmentationStepTransactions(
            toSendAmount: amount,
            recoverableMemo: recoverableMemo,
            feeLevel: feeLevel,
            rngSeed: RngSeed(),
            completion: completion)
    }

    public func prepareDefragmentationStepTransactions(
        toSendAmount amount: Amount,
        recoverableMemo: Bool = false,
        feeLevel: FeeLevel = .minimum,
        rngSeed: RngSeed,
        completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
    ) {
        Account.TransactionOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).prepareDefragmentationStepTransactions(
            toSendAmount: amount,
            recoverableMemo: recoverableMemo,
            feeLevel: feeLevel) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func submitDefragStepTransactions(
        transactions: [Transaction],
        completion: @escaping (Result<[UInt64], SubmitTransactionError>) -> Void
    ) {
        transactions.mapAsync({ transaction, callback in
            self.submitTransaction(transaction: transaction, completion: callback)
        },
        serialQueue: serialQueue,
        completion: { result in
            completion(result.map { $0.compactMap { $0 } })
        })
    }

    public func prepareTransaction(
        presignedInput: SignedContingentInput,
        fee: Amount,
        completion: @escaping (Result<PendingTransaction, TransactionPreparationError>)
        -> Void
    ) {
        guard let rngSeed = defaultRng.generateRngSeed() else {
            completion(.failure(
                TransactionPreparationError.invalidInput(
                    "Could not create 32-byte RNG seed")))
            return
        }

        Account.TransactionOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).preparePresignedInputTransaction(
            presignedInput: presignedInput,
            memoType: .unused,
            fee: fee) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func prepareTransaction(
        presignedInput: SignedContingentInput,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<PendingTransaction, TransactionPreparationError>)
        -> Void
    ) {
        guard let rngSeed = defaultRng.generateRngSeed() else {
            completion(.failure(
                TransactionPreparationError.invalidInput(
                    "Could not create 32-byte RNG seed")))
            return
        }

        Account.TransactionOperations(
            account: accountLock,
            fogMerkleProofService: serviceProvider.fogMerkleProofService,
            fogResolverManager: fogResolverManager,
            metaFetcher: metaFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            mixinSelectionStrategy: mixinSelectionStrategy,
            rngSeed: rngSeed,
            targetQueue: serialQueue
        ).preparePresignedInputTransaction(
            presignedInput: presignedInput,
            memoType: .unused,
            feeLevel: feeLevel) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func submitTransaction(
        transaction: Transaction,
        completion: @escaping (Result<UInt64, SubmitTransactionError>) -> Void
    ) {
        TransactionSubmitter(
            consensusService: serviceProvider.consensusService,
            metaFetcher: metaFetcher,
            syncChecker: accountLock.accessWithoutLocking.syncCheckerLock
        ).submitTransaction(transaction) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func txOutStatus(
        of transaction: Transaction,
        completion: @escaping (Result<TransactionStatus, ConnectionError>) -> Void
    ) {
        TransactionStatusTxOutChecker(
            account: accountLock,
            fogUntrustedTxOutService: serviceProvider.fogUntrustedTxOutService
        ).checkStatus(transaction) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func status(
        of transaction: Transaction,
        requireInBalance: Bool = true,
        completion: @escaping (Result<TransactionStatus, ConnectionError>) -> Void
    ) {
        TransactionStatusChecker(
            account: accountLock,
            fogUntrustedTxOutService: serviceProvider.fogUntrustedTxOutService,
            fogKeyImageService: serviceProvider.fogKeyImageService,
            targetQueue: serialQueue
        ).checkStatus(transaction, requireInBalance: requireInBalance) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func status(of receipt: Receipt) -> Result<ReceiptStatus, InvalidInputError> {
        ReceiptStatusChecker(account: accountLock).status(receipt)
    }

    public func blockVersion(
        _ completion: @escaping (Result<BlockVersion, ConnectionError>) -> Void
    ) {
        metaFetcher.blockVersion {
            completion($0)
        }
    }

}
