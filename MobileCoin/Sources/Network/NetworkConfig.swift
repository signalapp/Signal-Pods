//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import NIOSSL

struct NetworkConfig {
    static func make(consensusUrl: String, fogUrl: String, attestation: AttestationConfig)
        -> Result<NetworkConfig, InvalidInputError>
    {
        ConsensusUrl.make(string: consensusUrl).flatMap { consensusUrl in
            FogUrl.make(string: fogUrl).map { fogUrl in
                NetworkConfig(consensusUrl: consensusUrl, fogUrl: fogUrl, attestation: attestation)
            }
        }
    }

    let consensusUrl: ConsensusUrl
    let fogUrl: FogUrl

    private let attestation: AttestationConfig

    var consensusTrustRoots: [NIOSSLCertificate]?
    var fogTrustRoots: [NIOSSLCertificate]?

    var consensusAuthorization: BasicCredentials?
    var fogAuthorization: BasicCredentials?

    init(consensusUrl: ConsensusUrl, fogUrl: FogUrl, attestation: AttestationConfig) {
        logger.info("consensusUrl: \(consensusUrl), fogUrl: \(fogUrl)")
        self.consensusUrl = consensusUrl
        self.fogUrl = fogUrl
        self.attestation = attestation
    }

    var consensus: AttestedConnectionConfig<ConsensusUrl> {
        AttestedConnectionConfig(
            url: consensusUrl,
            attestation: attestation.consensus,
            trustRoots: consensusTrustRoots,
            authorization: consensusAuthorization)
    }

    var fogView: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            attestation: attestation.fogView,
            trustRoots: fogTrustRoots,
            authorization: fogAuthorization)
    }

    var fogMerkleProof: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            attestation: attestation.fogMerkleProof,
            trustRoots: fogTrustRoots,
            authorization: fogAuthorization)
    }

    var fogKeyImage: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            attestation: attestation.fogKeyImage,
            trustRoots: fogTrustRoots,
            authorization: fogAuthorization)
    }

    var fogBlock: ConnectionConfig<FogUrl> {
        ConnectionConfig(url: fogUrl, trustRoots: fogTrustRoots, authorization: fogAuthorization)
    }

    var fogUntrustedTxOut: ConnectionConfig<FogUrl> {
        ConnectionConfig(url: fogUrl, trustRoots: fogTrustRoots, authorization: fogAuthorization)
    }

    var fogReportAttestation: Attestation { attestation.fogReport }
}

extension NetworkConfig {
    struct AttestationConfig {
        static var devMrSigner: Self {
            // INTEL-SA-00334: LVI hardening is handled via rustc arguments set in
            // mc-util-build-enclave
            do {
                return .init(
                    consensus: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_CONSENSUS_MRSIGNER,
                        productId: McConstants.CONSENSUS_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogView: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_MRSIGNER,
                        productId: McConstants.FOG_VIEW_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_VIEW_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogKeyImage: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_LEDGER_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogMerkleProof: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_LEDGER_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogReport: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_REPORT_MRSIGNER,
                        productId: McConstants.FOG_REPORT_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_REPORT_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()))
            } catch {
                // Safety: MrSigner is guaranteed to be 32 bytes in length, so Attestation.init
                // should never fail.
                logger.fatalError("invalid configuration: \(error)")
            }
        }

        static var testNetMrSigner: Self {
            do {
                // INTEL-SA-00334: LVI hardening is handled via rustc arguments set in
                // mc-util-build-enclave
                return .init(
                    consensus: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_CONSENSUS_MRSIGNER,
                        productId: McConstants.CONSENSUS_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogView: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_FOG_MRSIGNER,
                        productId: McConstants.FOG_VIEW_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_VIEW_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogKeyImage: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_FOG_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_LEDGER_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogMerkleProof: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_FOG_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_LEDGER_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogReport: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_FOG_REPORT_MRSIGNER,
                        productId: McConstants.FOG_REPORT_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_REPORT_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()))
            } catch {
                // Safety: MrSigner is guaranteed to be 32 bytes in length, so Attestation.init
                // should never fail.
                logger.fatalError("invalid configuration: \(error)")
            }
        }

        let consensus: Attestation
        let fogView: Attestation
        let fogKeyImage: Attestation
        let fogMerkleProof: Attestation
        let fogReport: Attestation
    }
}
