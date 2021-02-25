//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count line_length multiline_function_chains

import Foundation

public final class MobileCoinClient {
    private let config: Config
    private let accountLock: ReadWriteDispatchLock<Account>
    private let inner: SerialDispatchLock<Inner>
    private let serialQueue: DispatchQueue
    private let callbackQueue: DispatchQueue

    /// - Returns: `MalformedInput` when `accountKey` isn't configured to use Fog.
    public static func make(accountKey: AccountKey, config: Config)
        -> Result<MobileCoinClient, MalformedInput>
    {
        guard let accountKey = AccountKeyWithFog(accountKey: accountKey) else {
            return .failure(
                MalformedInput("Accounts without fog URLs are not currently supported."))
        }

        return .success(Self(accountKey: accountKey, config: config))
    }

    init(accountKey: AccountKeyWithFog, config: Config) {
        self.config = config
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)")
        self.callbackQueue = config.callbackQueue ?? DispatchQueue.main
        self.accountLock = .init(Account(accountKey: accountKey))

        let networkConfig: NetworkConfig
        if let attestationConfig = config.attestationConfig {
            networkConfig = NetworkConfig(
                consensusUrl: config.consensusUrl,
                fogViewUrl: config.fogViewUrl,
                fogLedgerUrl: config.fogLedgerUrl,
                attestation: attestationConfig)
        } else {
            networkConfig = NetworkConfig(
                consensusUrl: config.consensusUrl,
                fogViewUrl: config.fogViewUrl,
                fogLedgerUrl: config.fogLedgerUrl)
        }

        let serviceProvider = DefaultServiceProvider(
            networkConfig: networkConfig,
            targetQueue: serialQueue)

        let fogResolverManager = FogResolverManager(
            fogReportAttestation: networkConfig.fogIngestAttestation,
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

    public func updateBalance(completion: @escaping (Result<Balance, Error>) -> Void) {
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

    public func minimumFee(amount: UInt64, completion: @escaping (Result<UInt64, Error>) -> Void) {
        FeeCalculator(targetQueue: serialQueue).minimumFee(amount: amount) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func baseFee(amount: UInt64, completion: @escaping (Result<UInt64, Error>) -> Void) {
        FeeCalculator(targetQueue: serialQueue).baseFee(amount: amount) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func priorityFee(amount: UInt64, completion: @escaping (Result<UInt64, Error>) -> Void) {
        FeeCalculator(targetQueue: serialQueue).priorityFee(amount: amount) { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }

    public func prepareTransaction(
        to recipient: PublicAddress,
        amount: UInt64,
        fee: UInt64,
        completion: @escaping (Result<(Transaction, Receipt), Error>) -> Void
    ) {
        inner.accessAsync {
            Account.TransactionPreparer(
                account: self.accountLock,
                fogMerkleProofService: $0.serviceProvider.fogMerkleProofService,
                fogResolverManager: $0.fogResolverManager,
                txOutSelectionStrategy: self.config.txOutSelectionStrategy,
                mixinSelectionStrategy: self.config.mixinSelectionStrategy,
                targetQueue: self.serialQueue
            ).prepareTransaction(
                to: recipient,
                amount: amount,
                fee: fee
            ) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func submitTransaction(
        _ transaction: Transaction,
        completion: @escaping (Result<(), Error>) -> Void
    ) {
        inner.accessAsync {
            TransactionSubmitter(
                consensusService: $0.serviceProvider.consensusService
            ).submitTransaction(transaction) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func status(
        of transaction: Transaction,
        completion: @escaping (Result<TransactionStatus, Error>) -> Void
    ) {
        inner.accessAsync {
            TransactionStatusChecker(
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

    public func status(
        of receipt: Receipt,
        completion: @escaping (Result<ReceiptStatus, Error>) -> Void
    ) {
        inner.accessAsync {
            ReceiptStatusChecker(
                account: self.accountLock,
                fogViewService: $0.serviceProvider.fogViewService,
                fogKeyImageService: $0.serviceProvider.fogKeyImageService,
                fogBlockService: $0.serviceProvider.fogBlockService,
                fogQueryScalingStrategy: self.config.fogQueryScalingStrategy,
                targetQueue: self.serialQueue
            ).checkStatus(receipt) { result in
                self.callbackQueue.async {
                    completion(result)
                }
            }
        }
    }

    public func defragmentAccount(completion: @escaping (Result<(), Error>) -> Void) {
        Account.TxOutConsolidator(
            account: accountLock,
            targetQueue: serialQueue
        ).consolidateTxOuts { result in
            self.callbackQueue.async {
                completion(result)
            }
        }
    }
}

extension MobileCoinClient {
    @available(*, deprecated, renamed: "MobileCoinClient.make(accountKey:config:)")
    public convenience init(accountKey: AccountKey, config: Config) throws {
        guard let accountKey = AccountKeyWithFog(accountKey: accountKey) else {
            throw MalformedInput("Accounts without fog URLs are not currently supported.")
        }

        self.init(accountKey: accountKey, config: config)
    }
}

extension MobileCoinClient {
    private final class Inner {
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
        fileprivate var consensusUrl: ConsensusUrl
        fileprivate var fogViewUrl: FogViewUrl
        fileprivate var fogLedgerUrl: FogLedgerUrl

        fileprivate var attestationConfig: NetworkConfig.AttestationConfig?

        public var cacheStorageAdapter: StorageAdapter?

        /// The `DispatchQueue` on which all `MobileCoinClient` completion handlers will be called.
        /// If `nil`, `DispatchQueue.main` will be used.
        public var callbackQueue: DispatchQueue?

        var txOutSelectionStrategy: TxOutSelectionStrategy = DefaultTxOutSelectionStrategy()
        var mixinSelectionStrategy: MixinSelectionStrategy = DefaultMixinSelectionStrategy()
        var fogQueryScalingStrategy: FogQueryScalingStrategy = DefaultFogQueryScalingStrategy()

        /// - Returns: `MalformedInput` when `consensusUrl`, `fogViewUrl`, or `fogLedgerUrl` are not
        ///     well-formed URLs with the appropriate schemes.
        public static func make(consensusUrl: String, fogViewUrl: String, fogLedgerUrl: String)
            -> Result<MobileCoinClient.Config, MalformedInput>
        {
            let consensusUrlTyped: ConsensusUrl
            let fogViewUrlTyped: FogViewUrl
            let fogLedgerUrlTyped: FogLedgerUrl
            do {
                consensusUrlTyped = try ConsensusUrl(string: consensusUrl)
                fogViewUrlTyped = try FogViewUrl(string: fogViewUrl)
                fogLedgerUrlTyped = try FogLedgerUrl(string: fogLedgerUrl)
            } catch {
                return .failure(MalformedInput(String(describing: error)))
            }

            return .success(
                Self(
                    consensusUrl: consensusUrlTyped,
                    fogViewUrl: fogViewUrlTyped,
                    fogLedgerUrl: fogLedgerUrlTyped))
        }

        /// - Returns: `MalformedInput` when `consensusUrl`, `fogViewUrl`, or `fogLedgerUrl` are not
        ///     well-formed URLs with the appropriate schemes.
        public static func make(
            consensusUrl: String,
            consensusAttestation: Attestation,
            fogViewUrl: String,
            fogViewAttestation: Attestation,
            fogLedgerUrl: String,
            fogKeyImageAttestation: Attestation,
            fogMerkleProofAttestation: Attestation,
            fogIngestAttestation: Attestation
        ) -> Result<MobileCoinClient.Config, MalformedInput> {
            let consensusUrlTyped: ConsensusUrl
            let fogViewUrlTyped: FogViewUrl
            let fogLedgerUrlTyped: FogLedgerUrl
            do {
                consensusUrlTyped = try ConsensusUrl(string: consensusUrl)
                fogViewUrlTyped = try FogViewUrl(string: fogViewUrl)
                fogLedgerUrlTyped = try FogLedgerUrl(string: fogLedgerUrl)
            } catch {
                return .failure(MalformedInput(String(describing: error)))
            }

            let attestationConfig = NetworkConfig.AttestationConfig(
                consensus: consensusAttestation,
                fogView: fogViewAttestation,
                fogKeyImage: fogKeyImageAttestation,
                fogMerkleProof: fogMerkleProofAttestation,
                fogIngest: fogIngestAttestation)

            return .success(
                Self(
                    consensusUrl: consensusUrlTyped,
                    fogViewUrl: fogViewUrlTyped,
                    fogLedgerUrl: fogLedgerUrlTyped,
                    attestationConfig: attestationConfig))
        }

        init(
            consensusUrl: ConsensusUrl,
            fogViewUrl: FogViewUrl,
            fogLedgerUrl: FogLedgerUrl,
            attestationConfig: NetworkConfig.AttestationConfig? = nil
        ) {
            self.consensusUrl = consensusUrl
            self.fogViewUrl = fogViewUrl
            self.fogLedgerUrl = fogLedgerUrl
            self.attestationConfig = attestationConfig
        }
    }
}

extension MobileCoinClient.Config {
    @available(*, deprecated, renamed:
        "MobileCoinClient.Config.make(consensusUrl:fogViewUrl:fogLedgerUrl:)")
    public init(consensusUrl: String, fogViewUrl: String, fogLedgerUrl: String) throws {
        self = try Self.make(
            consensusUrl: consensusUrl,
            fogViewUrl: fogViewUrl,
            fogLedgerUrl: fogLedgerUrl).get()
    }

    @available(*, deprecated, renamed:
        "MobileCoinClient.Config.make(consensusUrl:consensusAttestation:fogViewUrl:fogViewAttestation:fogLedgerUrl:fogKeyImageAttestation:fogMerkleProofAttestation:fogIngestAttestation:)")
    public init(
        consensusUrl: String,
        consensusAttestation: Attestation,
        fogViewUrl: String,
        fogViewAttestation: Attestation,
        fogLedgerUrl: String,
        fogKeyImageAttestation: Attestation,
        fogMerkleProofAttestation: Attestation,
        fogIngestAttestation: Attestation
    ) throws {
        self = try Self.make(
            consensusUrl: consensusUrl,
            consensusAttestation: consensusAttestation,
            fogViewUrl: fogViewUrl,
            fogViewAttestation: fogViewAttestation,
            fogLedgerUrl: fogLedgerUrl,
            fogKeyImageAttestation: fogKeyImageAttestation,
            fogMerkleProofAttestation: fogMerkleProofAttestation,
            fogIngestAttestation: fogIngestAttestation).get()
    }
}
