//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count multiline_arguments multiline_function_chains

import Foundation
import NIOSSL

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
    private let inner: SerialDispatchLock<Inner>
    private let serialQueue: DispatchQueue
    private let callbackQueue: DispatchQueue

    private let txOutSelectionStrategy: TxOutSelectionStrategy
    private let mixinSelectionStrategy: MixinSelectionStrategy
    private let fogQueryScalingStrategy: FogQueryScalingStrategy

    private let feeFetcher: BlockchainFeeFetcher

    init(accountKey: AccountKeyWithFog, config: Config) {
        logger.info("""
            Initializing \(Self.self):
            \(Self.configDescription(accountKey: accountKey, config: config))
            """, logFunction: false)

        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)")
        self.callbackQueue = config.callbackQueue ?? DispatchQueue.main
        self.accountLock = .init(Account(accountKey: accountKey))
        self.txOutSelectionStrategy = config.txOutSelectionStrategy
        self.mixinSelectionStrategy = config.mixinSelectionStrategy
        self.fogQueryScalingStrategy = config.fogQueryScalingStrategy

        let serviceProvider =
            DefaultServiceProvider(networkConfig: config.networkConfig, targetQueue: serialQueue)
        let fogResolverManager = FogResolverManager(
            fogReportAttestation: config.networkConfig.fogReportAttestation,
            serviceProvider: serviceProvider,
            targetQueue: serialQueue)

        let inner = Inner(serviceProvider: serviceProvider, fogResolverManager: fogResolverManager)
        self.inner = .init(inner, targetQueue: serialQueue)

        self.feeFetcher = BlockchainFeeFetcher(
            blockchainService: serviceProvider.blockchainService,
            minimumFeeCacheTTL: config.minimumFeeCacheTTL,
            targetQueue: serialQueue)
    }

    public var balance: Balance {
        accountLock.readSync { $0.cachedBalance }
    }

    public var accountActivity: AccountActivity {
        accountLock.readSync { $0.cachedAccountActivity }
    }

    public func setConsensusBasicAuthorization(username: String, password: String) {
        let credentials = BasicCredentials(username: username, password: password)
        inner.accessAsync { $0.serviceProvider.setConsensusAuthorization(credentials: credentials) }
    }

    public func setFogBasicAuthorization(username: String, password: String) {
        let credentials = BasicCredentials(username: username, password: password)
        inner.accessAsync { $0.serviceProvider.setFogUserAuthorization(credentials: credentials) }
    }

    public func updateBalance(completion: @escaping (Result<Balance, ConnectionError>) -> Void) {
        inner.accessAsync {
            Account.BalanceUpdater(
                account: self.accountLock,
                fogViewService: $0.serviceProvider.fogViewService,
                fogKeyImageService: $0.serviceProvider.fogKeyImageService,
                fogBlockService: $0.serviceProvider.fogBlockService,
                fogQueryScalingStrategy: self.fogQueryScalingStrategy,
                targetQueue: self.serialQueue
            ).updateBalance { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func amountTransferable(
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<UInt64, BalanceTransferEstimationFetcherError>) -> Void
    ) {
        Account.TransactionEstimator(
            account: accountLock,
            feeFetcher: feeFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).amountTransferable(feeLevel: feeLevel, completion: completion)
    }

    public func estimateTotalFee(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<UInt64, TransactionEstimationFetcherError>) -> Void
    ) {
        Account.TransactionEstimator(
            account: accountLock,
            feeFetcher: feeFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).estimateTotalFee(toSendAmount: amount, feeLevel: feeLevel, completion: completion)
    }

    public func requiresDefragmentation(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<Bool, TransactionEstimationFetcherError>) -> Void
    ) {
        Account.TransactionEstimator(
            account: accountLock,
            feeFetcher: feeFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).requiresDefragmentation(toSendAmount: amount, feeLevel: feeLevel, completion: completion)
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        amount: UInt64,
        fee: UInt64,
        completion: @escaping (
            Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
        ) -> Void
    ) {
        inner.accessAsync {
            Account.TransactionOperations(
                account: self.accountLock,
                fogMerkleProofService: $0.serviceProvider.fogMerkleProofService,
                fogResolverManager: $0.fogResolverManager,
                feeFetcher: self.feeFetcher,
                txOutSelectionStrategy: self.txOutSelectionStrategy,
                mixinSelectionStrategy: self.mixinSelectionStrategy,
                targetQueue: self.serialQueue
            ).prepareTransaction(to: recipient, amount: amount, fee: fee) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        amount: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (
            Result<(transaction: Transaction, receipt: Receipt), TransactionPreparationError>
        ) -> Void
    ) {
        inner.accessAsync {
            Account.TransactionOperations(
                account: self.accountLock,
                fogMerkleProofService: $0.serviceProvider.fogMerkleProofService,
                fogResolverManager: $0.fogResolverManager,
                feeFetcher: self.feeFetcher,
                txOutSelectionStrategy: self.txOutSelectionStrategy,
                mixinSelectionStrategy: self.mixinSelectionStrategy,
                targetQueue: self.serialQueue
            ).prepareTransaction(to: recipient, amount: amount, feeLevel: feeLevel) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func prepareDefragmentationStepTransactions(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel = .minimum,
        completion: @escaping (Result<[Transaction], DefragTransactionPreparationError>) -> Void
    ) {
        inner.accessAsync {
            Account.TransactionOperations(
                account: self.accountLock,
                fogMerkleProofService: $0.serviceProvider.fogMerkleProofService,
                fogResolverManager: $0.fogResolverManager,
                feeFetcher: self.feeFetcher,
                txOutSelectionStrategy: self.txOutSelectionStrategy,
                mixinSelectionStrategy: self.mixinSelectionStrategy,
                targetQueue: self.serialQueue
            ).prepareDefragmentationStepTransactions(toSendAmount: amount, feeLevel: feeLevel)
            { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func submitTransaction(
        _ transaction: Transaction,
        completion: @escaping (Result<(), TransactionSubmissionError>) -> Void
    ) {
        inner.accessAsync {
            TransactionSubmitter(
                consensusService: $0.serviceProvider.consensusService,
                feeFetcher: self.feeFetcher
            ).submitTransaction(transaction) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func status(
        of transaction: Transaction,
        completion: @escaping (Result<TransactionStatus, ConnectionError>) -> Void
    ) {
        inner.accessAsync {
            TransactionStatusChecker(
                account: self.accountLock,
                fogUntrustedTxOutService: $0.serviceProvider.fogUntrustedTxOutService,
                fogKeyImageService: $0.serviceProvider.fogKeyImageService,
                targetQueue: self.serialQueue
            ).checkStatus(transaction) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func status(of receipt: Receipt) -> Result<ReceiptStatus, InvalidInputError> {
        ReceiptStatusChecker(account: accountLock).status(receipt)
    }
}

extension MobileCoinClient {
    private static func configDescription(accountKey: AccountKeyWithFog, config: Config) -> String {
        let fogInfo = accountKey.fogInfo
        return """
            Consensus url: \(config.networkConfig.consensusUrl.url)
            Fog url: \(config.networkConfig.fogUrl.url)
            AccountKey PublicAddress: \
            \(redacting: Base58Coder.encode(accountKey.accountKey.publicAddress))
            AccountKey Fog Report url: \(fogInfo.reportUrl.url)
            AccountKey Fog Report id: \(String(reflecting: fogInfo.reportId))
            AccountKey Fog Report authority sPKI: 0x\(fogInfo.authoritySpki.hexEncodedString())
            Consensus attestation: \(config.networkConfig.consensus.attestation)
            Fog View attestation: \(config.networkConfig.fogView.attestation)
            Fog KeyImage attestation: \(config.networkConfig.fogKeyImage.attestation)
            Fog MerkleProof attestation: \(config.networkConfig.fogMerkleProof.attestation)
            Fog Report attestation: \(config.networkConfig.fogReportAttestation)
            """
    }
}

extension MobileCoinClient {
    @available(*, deprecated, message: "Use amountTransferable(feeLevel:completion:) instead")
    public func amountTransferable(feeLevel: FeeLevel = .minimum)
        -> Result<UInt64, BalanceTransferEstimationError>
    {
        Account.TransactionEstimator(
            account: accountLock,
            feeFetcher: feeFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).amountTransferable(feeLevel: feeLevel)
    }

    @available(*, deprecated, message:
        "Use estimateTotalFee(toSendAmount:feeLevel:completion:) instead")
    public func estimateTotalFee(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel = .minimum
    ) -> Result<UInt64, TransactionEstimationError> {
        Account.TransactionEstimator(
            account: accountLock,
            feeFetcher: feeFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).estimateTotalFee(toSendAmount: amount, feeLevel: feeLevel)
    }

    @available(*, deprecated, message:
        "Use requiresDefragmentation(toSendAmount:feeLevel:completion:) instead")
    public func requiresDefragmentation(toSendAmount amount: UInt64, feeLevel: FeeLevel = .minimum)
        -> Result<Bool, TransactionEstimationError>
    {
        Account.TransactionEstimator(
            account: accountLock,
            feeFetcher: feeFetcher,
            txOutSelectionStrategy: txOutSelectionStrategy,
            targetQueue: serialQueue
        ).requiresDefragmentation(toSendAmount: amount, feeLevel: feeLevel)
    }
}

extension MobileCoinClient {
    private struct Inner {
        let serviceProvider: ServiceProvider
        let fogResolverManager: FogResolverManager

        init(serviceProvider: ServiceProvider, fogResolverManager: FogResolverManager) {
            self.serviceProvider = serviceProvider
            self.fogResolverManager = fogResolverManager
        }
    }
}

extension MobileCoinClient {
    public struct Config {
        /// - Returns: `InvalidInputError` when `consensusUrl` or `fogUrl` are not well-formed URLs
        ///     with the appropriate schemes.
        public static func make(
            consensusUrl: String,
            consensusAttestation: Attestation,
            fogUrl: String,
            fogViewAttestation: Attestation,
            fogKeyImageAttestation: Attestation,
            fogMerkleProofAttestation: Attestation,
            fogReportAttestation: Attestation
        ) -> Result<Config, InvalidInputError> {
            ConsensusUrl.make(string: consensusUrl).flatMap { consensusUrl in
                FogUrl.make(string: fogUrl).map { fogUrl in
                    let attestationConfig = NetworkConfig.AttestationConfig(
                        consensus: consensusAttestation,
                        fogView: fogViewAttestation,
                        fogKeyImage: fogKeyImageAttestation,
                        fogMerkleProof: fogMerkleProofAttestation,
                        fogReport: fogReportAttestation)
                    let networkConfig = NetworkConfig(
                        consensusUrl: consensusUrl,
                        fogUrl: fogUrl,
                        attestation: attestationConfig)
                    return Config(networkConfig: networkConfig)
                }
            }
        }

        fileprivate var networkConfig: NetworkConfig

        // default minimum fee cache TTL is 30 minutes
        public var minimumFeeCacheTTL: TimeInterval = 30 * 60

        public var cacheStorageAdapter: StorageAdapter?

        /// The `DispatchQueue` on which all `MobileCoinClient` completion handlers will be called.
        /// If `nil`, `DispatchQueue.main` will be used.
        public var callbackQueue: DispatchQueue?

        var txOutSelectionStrategy: TxOutSelectionStrategy = DefaultTxOutSelectionStrategy()
        var mixinSelectionStrategy: MixinSelectionStrategy = DefaultMixinSelectionStrategy()
        var fogQueryScalingStrategy: FogQueryScalingStrategy = DefaultFogQueryScalingStrategy()

        init(networkConfig: NetworkConfig) {
            self.networkConfig = networkConfig
        }

        public mutating func setConsensusTrustRoots(_ trustRoots: [Data])
            -> Result<(), InvalidInputError>
        {
            Self.parseTrustRoots(trustRootsBytes: trustRoots).map { trustRoots in
                networkConfig.consensusTrustRoots = trustRoots
            }
        }

        public mutating func setFogTrustRoots(_ trustRoots: [Data]) -> Result<(), InvalidInputError>
        {
            Self.parseTrustRoots(trustRootsBytes: trustRoots).map { trustRoots in
                networkConfig.fogTrustRoots = trustRoots
            }
        }

        private static func parseTrustRoots(trustRootsBytes: [Data])
            -> Result<[NIOSSLCertificate], InvalidInputError>
        {
            var trustRoots: [NIOSSLCertificate] = []
            for trustRootBytes in trustRootsBytes {
                do {
                    trustRoots.append(
                        try NIOSSLCertificate(bytes: Array(trustRootBytes), format: .der))
                } catch {
                    let errorMessage = "Error parsing trust root certificate: " +
                        "\(trustRootBytes.base64EncodedString()) - Error: \(error)"
                    logger.error(errorMessage, logFunction: false)
                    return .failure(InvalidInputError(errorMessage))
                }
            }
            return .success(trustRoots)
        }

        public mutating func setConsensusBasicAuthorization(username: String, password: String) {
            networkConfig.consensusAuthorization =
                BasicCredentials(username: username, password: password)
        }

        public mutating func setFogBasicAuthorization(username: String, password: String) {
            networkConfig.fogUserAuthorization =
                BasicCredentials(username: username, password: password)
        }
    }
}
