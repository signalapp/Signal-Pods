//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation

struct NetworkConfig {
    let consensusUrl: ConsensusUrl
    let fogViewUrl: FogViewUrl
    let fogKeyImageUrl: FogLedgerUrl
    let fogMerkleProofUrl: FogLedgerUrl
    let fogBlockUrl: FogLedgerUrl
    let fogUntrustedTxOutUrl: FogLedgerUrl

    private let attestationConfig: AttestationConfig

    init(
        consensusUrl: String,
        fogViewUrl: String,
        fogLedgerUrl: String,
        attestationConfig: AttestationConfig = .devMrSigner
    ) throws {
        self.init(
            consensusUrl: try ConsensusUrl(string: consensusUrl),
            fogViewUrl: try FogViewUrl(string: fogViewUrl),
            fogLedgerUrl: try FogLedgerUrl(string: fogLedgerUrl),
            attestation: attestationConfig)
    }

    init(
        consensusUrl: ConsensusUrl,
        fogViewUrl: FogViewUrl,
        fogLedgerUrl: FogLedgerUrl,
        attestation attestationConfig: AttestationConfig = .devMrSigner
    ) {
        self.consensusUrl = consensusUrl
        self.fogViewUrl = fogViewUrl
        self.fogKeyImageUrl = fogLedgerUrl
        self.fogMerkleProofUrl = fogLedgerUrl
        self.fogBlockUrl = fogLedgerUrl
        self.fogUntrustedTxOutUrl = fogLedgerUrl
        self.attestationConfig = attestationConfig
    }

    var consensusAttestation: Attestation { attestationConfig.consensus }
    var fogViewAttestation: Attestation { attestationConfig.fogView }
    var fogKeyImageAttestation: Attestation { attestationConfig.fogKeyImage }
    var fogMerkleProofAttestation: Attestation { attestationConfig.fogMerkleProof }
    var fogIngestAttestation: Attestation { attestationConfig.fogIngest }
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
                    fogIngest: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_INGEST_MRSIGNER,
                        productId: McConstants.FOG_INGEST_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.CONSENSUS_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()))
            } catch {
                // Safety: MrSigner is guaranteed to be 32 bytes in length, so Attestation.init
                // should never fail.
                fatalError("\(Self.self).\(#function): invalid configuration: \(error)")
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
                    fogIngest: try Attestation(Attestation.MrSigner.make(
                        mrSigner: McConstants.DEV_FOG_INGEST_MRSIGNER,
                        productId: McConstants.FOG_INGEST_PRODUCT_ID,
                        minimumSecurityVersion: McConstants.FOG_INGEST_SECURITY_VERSION,
                        allowedHardeningAdvisories: ["INTEL-SA-00334"]).get()))
            } catch {
                // Safety: MrSigner is guaranteed to be 32 bytes in length, so Attestation.init
                // should never fail.
                fatalError("\(Self.self).\(#function): invalid configuration: \(error)")
            }
        }

        let consensus: Attestation
        let fogView: Attestation
        let fogKeyImage: Attestation
        let fogMerkleProof: Attestation
        let fogIngest: Attestation
    }
}
