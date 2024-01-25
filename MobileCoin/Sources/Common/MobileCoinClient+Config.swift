//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
// swiftlint:disable line_length closure_body_length
// swiftlint:disable function_parameter_count multiline_function_chains

import Foundation

extension MobileCoinClient {
    public struct Config {
        /// - Returns: `InvalidInputError` when `consensusUrl` or `fogUrl`  are not well-formed URLs
        ///     with the appropriate schemes.
        public static func make(
            consensusUrl: String,
            consensusAttestation: Attestation,
            fogUrl: String,
            fogViewAttestation: Attestation,
            fogKeyImageAttestation: Attestation,
            fogMerkleProofAttestation: Attestation,
            fogReportAttestation: Attestation,
            transportProtocol: TransportProtocol
        ) -> Result<Config, InvalidInputError> {
            Self.make(consensusUrls: [consensusUrl],
                      consensusAttestation: consensusAttestation,
                      fogUrls: [fogUrl],
                      fogViewAttestation: fogViewAttestation,
                      fogKeyImageAttestation: fogKeyImageAttestation,
                      fogMerkleProofAttestation: fogMerkleProofAttestation,
                      fogReportAttestation: fogReportAttestation,
                      transportProtocol: transportProtocol)
        }

        /// - Returns: `InvalidInputError` when `consensusUrl` or `fogUrl or `mistyswapUrl` are not well-formed URLs
        ///     with the appropriate schemes.
        public static func make(
            consensusUrl: String,
            consensusAttestation: Attestation,
            fogUrl: String,
            fogViewAttestation: Attestation,
            fogKeyImageAttestation: Attestation,
            fogMerkleProofAttestation: Attestation,
            fogReportAttestation: Attestation,
            mistyswapUrl: String,
            mistyswapAttestation: Attestation,
            transportProtocol: TransportProtocol
        ) -> Result<Config, InvalidInputError> {
            Self.make(consensusUrls: [consensusUrl],
                      consensusAttestation: consensusAttestation,
                      fogUrls: [fogUrl],
                      fogViewAttestation: fogViewAttestation,
                      fogKeyImageAttestation: fogKeyImageAttestation,
                      fogMerkleProofAttestation: fogMerkleProofAttestation,
                      fogReportAttestation: fogReportAttestation,
                      mistyswapUrls: [mistyswapUrl],
                      mistyswapAttestation: mistyswapAttestation,
                      transportProtocol: transportProtocol)
        }

        /// - Returns: `InvalidInputError` when `consensusUrl` or `fogUrl` are not well-formed URLs
        ///     with the appropriate schemes.
        public static func make(
            consensusUrls: [String],
            consensusAttestation: Attestation,
            fogUrls: [String],
            fogViewAttestation: Attestation,
            fogKeyImageAttestation: Attestation,
            fogMerkleProofAttestation: Attestation,
            fogReportAttestation: Attestation,
            mistyswapUrls: [String],
            mistyswapAttestation: Attestation,
            transportProtocol: TransportProtocol
        ) -> Result<Config, InvalidInputError> {

            ConsensusUrl.make(strings: consensusUrls).flatMap { consensusUrls in
                RandomUrlLoadBalancer<ConsensusUrl>.make(
                    urls: consensusUrls
                ).flatMap { consensusUrlLoadBalancer in
                    FogUrl.make(strings: fogUrls).flatMap { fogUrls in
                        RandomUrlLoadBalancer<FogUrl>.make(
                            urls: fogUrls
                        ).flatMap { fogUrlLoadBalancer in
                            MistyswapUrl.make(strings: mistyswapUrls).flatMap { mistyswapUrls in
                                NonRotatingUrlLoadBalancer<MistyswapUrl>.make(
                                    urls: mistyswapUrls
                                ).map { mistyswapLoadBalancer in

                                    let attestationConfig = NetworkConfig.AttestationConfig(
                                        consensus: consensusAttestation,
                                        fogView: fogViewAttestation,
                                        fogKeyImage: fogKeyImageAttestation,
                                        fogMerkleProof: fogMerkleProofAttestation,
                                        fogReport: fogReportAttestation,
                                        mistyswap: mistyswapAttestation
                                    )

                                    let networkConfig = NetworkConfig(
                                        consensusUrlLoadBalancer: consensusUrlLoadBalancer,
                                        fogUrlLoadBalancer: fogUrlLoadBalancer,
                                        attestation: attestationConfig,
                                        transportProtocol: transportProtocol,
                                        mistyswapLoadBalancer: mistyswapLoadBalancer)

                                    return Config(networkConfig: networkConfig)
                                }
                            }
                        }
                    }
                }
            }
        }

        /// - Returns: `InvalidInputError` when `consensusUrl` or `fogUrl` are not well-formed URLs
        ///     with the appropriate schemes.
        public static func make(
            consensusUrls: [String],
            consensusAttestation: Attestation,
            fogUrls: [String],
            fogViewAttestation: Attestation,
            fogKeyImageAttestation: Attestation,
            fogMerkleProofAttestation: Attestation,
            fogReportAttestation: Attestation,
            transportProtocol: TransportProtocol
        ) -> Result<Config, InvalidInputError> {

            ConsensusUrl.make(strings: consensusUrls).flatMap { consensusUrls in
                RandomUrlLoadBalancer<ConsensusUrl>.make(
                    urls: consensusUrls
                ).flatMap { consensusUrlLoadBalancer in
                    FogUrl.make(strings: fogUrls).flatMap { fogUrls in
                        RandomUrlLoadBalancer<FogUrl>.make(
                            urls: fogUrls
                        ).flatMap { fogUrlLoadBalancer in

                            let attestationConfig = NetworkConfig.AttestationConfig(
                                consensus: consensusAttestation,
                                fogView: fogViewAttestation,
                                fogKeyImage: fogKeyImageAttestation,
                                fogMerkleProof: fogMerkleProofAttestation,
                                fogReport: fogReportAttestation,
                                mistyswap: nil
                            )

                            let networkConfig = NetworkConfig(
                                consensusUrlLoadBalancer: consensusUrlLoadBalancer,
                                fogUrlLoadBalancer: fogUrlLoadBalancer,
                                attestation: attestationConfig,
                                transportProtocol: transportProtocol,
                                mistyswapLoadBalancer: nil
                            )

                            return .success(Config(networkConfig: networkConfig))
                        }
                    }
                }
            }
        }

        var networkConfig: NetworkConfig

        // default minimum fee cache TTL is 30 minutes
        public var metaCacheTTL: TimeInterval = 30 * 60

        public var cacheStorageAdapter: StorageAdapter?

        /// The `DispatchQueue` on which all `MobileCoinClient` completion handlers will be called.
        /// If `nil`, `DispatchQueue.main` will be used.
        public var callbackQueue: DispatchQueue?

        var txOutSelectionStrategy: TxOutSelectionStrategy = DefaultTxOutSelectionStrategy()
        var mixinSelectionStrategy: MixinSelectionStrategy = DefaultMixinSelectionStrategy()
        var fogQueryScalingStrategy: FogQueryScalingStrategy = DefaultFogQueryScalingStrategy()
        var fogSyncCheckable: FogSyncCheckable = FogSyncChecker()

        init(networkConfig: NetworkConfig) {
            self.networkConfig = networkConfig
        }

        public var transportProtocol: TransportProtocol {
            get { networkConfig.transportProtocol }
            set { networkConfig.transportProtocol = newValue }
        }

        public mutating func setConsensusTrustRoots(_ trustRoots: [Data])
            -> Result<(), InvalidInputError>
        {
            networkConfig.setConsensusTrustRoots(trustRoots)
        }

        public mutating func setFogTrustRoots(_ trustRoots: [Data]) -> Result<(), InvalidInputError>
        {
            networkConfig.setFogTrustRoots(trustRoots)
        }

        public mutating func setConsensusBasicAuthorization(username: String, password: String) {
            networkConfig.consensusAuthorization =
                BasicCredentials(username: username, password: password)
        }

        public mutating func setFogBasicAuthorization(username: String, password: String) {
            networkConfig.fogUserAuthorization =
                BasicCredentials(username: username, password: password)
        }

        public var httpRequester: HttpRequester? {
            get { networkConfig.httpRequester }
            set { networkConfig.httpRequester = newValue }
        }
    }
}

extension MobileCoinClient {
    static func configDescription(accountKey: AccountKeyWithFog, config: Config) -> String {
        let fogInfo = accountKey.fogInfo

        let mistyswapInfo = config.networkConfig.mistyswapConfig()?.attestation.description
            ?? "none"

        return """
            Consensus urls: \(config.networkConfig.consensusUrls)
            Fog urls: \(config.networkConfig.fogUrls)
            AccountKey PublicAddress: \
            \(redacting: Base58Coder.encode(accountKey.accountKey.publicAddress))
            AccountKey Fog Report url: \(fogInfo.reportUrl.url)
            AccountKey Fog Report id: \(String(reflecting: fogInfo.reportId))
            AccountKey Fog Report authority sPKI: 0x\(fogInfo.authoritySpki.hexEncodedString())
            Consensus attestation: \(config.networkConfig.consensusConfig().attestation)
            Fog View attestation: \(config.networkConfig.fogViewConfig().attestation)
            Fog KeyImage attestation: \(config.networkConfig.fogKeyImageConfig().attestation)
            Fog MerkleProof attestation: \(config.networkConfig.fogMerkleProofConfig().attestation)
            Fog Report attestation: \(config.networkConfig.fogReportAttestation)
            Mistyswap attestation: \(mistyswapInfo)
            """
    }
}
