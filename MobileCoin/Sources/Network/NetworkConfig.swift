//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import NIOSSL

struct NetworkConfig {
    static func make(
        consensusUrl: String,
        fogUrl: String,
        attestationConfig: AttestationConfig = .devMrSigner
    ) -> Result<NetworkConfig, InvalidInputError> {
        ConsensusUrl.make(string: consensusUrl).flatMap { consensusUrl in
            FogUrl.make(string: fogUrl).map { fogUrl in
                NetworkConfig(
                    consensusUrl: consensusUrl,
                    fogUrl: fogUrl,
                    attestation: attestationConfig)
            }
        }
    }

    let consensusUrl: ConsensusUrl
    let fogUrl: FogUrl

    private let attestationConfig: AttestationConfig

    var consensusTrustRoots: [NIOSSLCertificate]?
    var fogTrustRoots: [NIOSSLCertificate]?

    init(
        consensusUrl: ConsensusUrl,
        fogUrl: FogUrl,
        attestation attestationConfig: AttestationConfig = .devMrSigner
    ) {
        self.consensusUrl = consensusUrl
        self.fogUrl = fogUrl
        self.attestationConfig = attestationConfig
    }

    var consensusAttestation: Attestation { attestationConfig.consensus }
    var fogViewAttestation: Attestation { attestationConfig.fogView }
    var fogKeyImageAttestation: Attestation { attestationConfig.fogKeyImage }
    var fogMerkleProofAttestation: Attestation { attestationConfig.fogMerkleProof }
    var fogReportAttestation: Attestation { attestationConfig.fogReport }
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
                        mrSigner: McConstants.DEV_FOG_VIEW_MRSIGNER,
                        productId: McConstants.FOG_VIEW_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogKeyImage: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_LEDGER_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogMerkleProof: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_LEDGER_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogReport: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_REPORT_MRSIGNER,
                        productId: McConstants.FOG_REPORT_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()))
            } catch {
                // Safety: MrSigner is guaranteed to be 32 bytes in length, so Attestation.init
                // should never fail.
                logger.fatalError("\(Self.self).\(#function): invalid configuration: \(error)")
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
                        mrSigner: McConstants.TESTNET_FOG_VIEW_MRSIGNER,
                        productId: McConstants.FOG_VIEW_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_VIEW_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogKeyImage: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_FOG_LEDGER_MRSIGNER,
                        productId: McConstants.FOG_LEDGER_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_LEDGER_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()),
                    fogMerkleProof: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.TESTNET_FOG_LEDGER_MRSIGNER,
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
                logger.fatalError("\(Self.self).\(#function): invalid configuration: \(error)")
            }
        }

        let consensus: Attestation
        let fogView: Attestation
        let fogKeyImage: Attestation
        let fogMerkleProof: Attestation
        let fogReport: Attestation
    }
}
