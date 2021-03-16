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
            return .failure(
                InvalidInputError("Accounts without fog URLs are not currently supported."))
        }

        return .success(MobileCoinClient(accountKey: accountKey, config: config))
    }

    private let config: Config
    private let accountLock: ReadWriteDispatchLock<Account>
    private let inner: SerialDispatchLock<Inner>
    private let serialQueue: DispatchQueue
    private let callbackQueue: DispatchQueue

    init(accountKey: AccountKeyWithFog, config: Config) {
        let networkConfig: NetworkConfig = {
            var networkConfig: NetworkConfig
            if let attestationConfig = config.attestationConfig {
                networkConfig = NetworkConfig(
                    consensusUrl: config.consensusUrl,
                    fogUrl: config.fogUrl,
                    attestation: attestationConfig)
            } else {
            	networkConfig = NetworkConfig(consensusUrl: config.consensusUrl, fogUrl: config.fogUrl)
            }
            networkConfig.consensusTrustRoots = config.consensusTrustRoots
            networkConfig.fogTrustRoots = config.fogTrustRoots
            return networkConfig
        }()

        logger.info("""
            Initializing MobileCoinClient:
            \(Self.configDescription(
                accountKey: accountKey,
                config: config,
                networkConfig: networkConfig))
            """)

        self.config = config
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)")
        self.callbackQueue = config.callbackQueue ?? DispatchQueue.main
        self.accountLock = .init(Account(accountKey: accountKey))

        let serviceProvider = DefaultServiceProvider(
            networkConfig: networkConfig,
            targetQueue: serialQueue)

        let fogResolverManager = FogResolverManager(
            fogReportAttestation: networkConfig.fogReportAttestation,
            serviceProvider: serviceProvider,
            targetQueue: serialQueue)

        let inner = Inner(
            serviceProvider: serviceProvider,
            fogResolverManager: fogResolverManager)
        self.inner = .init(inner, targetQueue: serialQueue)
    }

    public var balance: Balance {
        accountLock.readSync { $0.cachedBalance }
    }

    public var accountActivity: AccountActivity {
        accountLock.readSync { $0.cachedAccountActivity }
    }

    public func setBasicAuthorization(username: String, password: String) {
        let credentials = BasicCredentials(username: username, password: password)
        inner.accessAsync { $0.serviceProvider.setAuthorization(credentials: credentials) }
    }

    public func updateBalance(completion: @escaping (Result<Balance, ConnectionError>) -> Void) {
        inner.accessAsync {
            Account.BalanceUpdater(
                account: self.accountLock,
                fogViewService: $0.serviceProvider.fogViewService,
                fogKeyImageService: $0.serviceProvider.fogKeyImageService,
                fogBlockService: $0.serviceProvider.fogBlockService,
                fogQueryScalingStrategy: self.config.fogQueryScalingStrategy,
                targetQueue: self.serialQueue
            ).updateBalance { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func amountTransferable(feeLevel: FeeLevel = .minimum)
        -> Result<UInt64, BalanceTransferEstimationError>
    {
        Account.TransactionEstimator(
            account: accountLock,
            txOutSelectionStrategy: self.config.txOutSelectionStrategy
        ).amountTransferable(feeLevel: feeLevel)
    }

    public func estimateTotalFee(
        toSendAmount amount: UInt64,
        feeLevel: FeeLevel = .minimum
    ) -> Result<UInt64, TransactionEstimationError> {
        Account.TransactionEstimator(
            account: accountLock,
            txOutSelectionStrategy: self.config.txOutSelectionStrategy
        ).estimateTotalFee(toSendAmount: amount, feeLevel: feeLevel)
    }

    public func requiresDefragmentation(toSendAmount amount: UInt64, feeLevel: FeeLevel = .minimum)
        -> Result<Bool, TransactionEstimationError>
    {
        Account.TransactionEstimator(
            account: accountLock,
            txOutSelectionStrategy: self.config.txOutSelectionStrategy
        ).requiresDefragmentation(toSendAmount: amount, feeLevel: feeLevel)
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
                txOutSelectionStrategy: self.config.txOutSelectionStrategy,
                mixinSelectionStrategy: self.config.mixinSelectionStrategy,
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
                txOutSelectionStrategy: self.config.txOutSelectionStrategy,
                mixinSelectionStrategy: self.config.mixinSelectionStrategy,
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
                txOutSelectionStrategy: self.config.txOutSelectionStrategy,
                mixinSelectionStrategy: self.config.mixinSelectionStrategy,
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
            TransactionSubmitter(consensusService: $0.serviceProvider.consensusService)
                .submitTransaction(transaction) { result in
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
    private static func configDescription(
        accountKey: AccountKeyWithFog,
        config: Config,
        networkConfig: NetworkConfig
    ) -> String {
        let fogInfo = accountKey.fogInfo
        return """
            Consensus url: \(String(reflecting: config.consensusUrl.url))
            Fog url: \(String(reflecting: config.fogUrl.url))
            AccountKey Fog Report url: \(String(reflecting: fogInfo.reportUrl.url))
            AccountKey Fog Report id: \(String(reflecting: fogInfo.reportId))
            AccountKey Fog Report authority sPKI: 0x\(fogInfo.authoritySpki.hexEncodedString())
            Consensus attestation: \(networkConfig.consensusAttestation)
            Fog View attestation: \(networkConfig.fogViewAttestation)
            Fog KeyImage attestation: \(networkConfig.fogKeyImageAttestation)
            Fog MerkleProof attestation: \(networkConfig.fogMerkleProofAttestation)
            Fog Report attestation: \(networkConfig.fogReportAttestation)
            """
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
        public static func make(consensusUrl: String, fogUrl: String)
            -> Result<Config, InvalidInputError>
        {
            ConsensusUrl.make(string: consensusUrl).flatMap { consensusUrl in
                FogUrl.make(string: fogUrl).map { fogUrl in
                    Config(consensusUrl: consensusUrl, fogUrl: fogUrl)
                }
            }
        }

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
                    return Config(
                        consensusUrl: consensusUrl,
                        fogUrl: fogUrl,
                        attestationConfig: attestationConfig)
                }
            }
        }

        fileprivate var consensusUrl: ConsensusUrl
        fileprivate var fogUrl: FogUrl

        fileprivate var attestationConfig: NetworkConfig.AttestationConfig?

        fileprivate var consensusTrustRoots: [NIOSSLCertificate]?
        fileprivate var fogTrustRoots: [NIOSSLCertificate]?

        public var cacheStorageAdapter: StorageAdapter?

        /// The `DispatchQueue` on which all `MobileCoinClient` completion handlers will be called.
        /// If `nil`, `DispatchQueue.main` will be used.
        public var callbackQueue: DispatchQueue?

        var txOutSelectionStrategy: TxOutSelectionStrategy = DefaultTxOutSelectionStrategy()
        var mixinSelectionStrategy: MixinSelectionStrategy = DefaultMixinSelectionStrategy()
        var fogQueryScalingStrategy: FogQueryScalingStrategy = DefaultFogQueryScalingStrategy()

        init(
            consensusUrl: ConsensusUrl,
            fogUrl: FogUrl,
            attestationConfig: NetworkConfig.AttestationConfig? = nil
        ) {
            self.consensusUrl = consensusUrl
            self.fogUrl = fogUrl
            self.attestationConfig = attestationConfig
        }

        public mutating func setConsensusTrustRoots(_ trustRoots: [Data])
            -> Result<(), InvalidInputError>
        {
            do {
                consensusTrustRoots =
                    try trustRoots.map { try NIOSSLCertificate(bytes: Array($0), format: .der) }
            } catch {
                return .failure(InvalidInputError("Failed parsing Consensus trust roots: \(error)"))
            }
            return .success(())
        }

        public mutating func setFogTrustRoots(_ trustRoots: [Data]) -> Result<(), InvalidInputError>
        {
            do {
                fogTrustRoots =
                    try trustRoots.map { try NIOSSLCertificate(bytes: Array($0), format: .der) }
            } catch {
                return .failure(InvalidInputError("Failed parsing Fog trust roots: \(error)"))
            }
            return .success(())
        }
    }
}
