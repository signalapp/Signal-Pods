//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

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
    var fogUserAuthorization: BasicCredentials?

    init(consensusUrl: ConsensusUrl, fogUrl: FogUrl, attestation: AttestationConfig) {
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

    var blockchain: ConnectionConfig<ConsensusUrl> {
        ConnectionConfig(
            url: consensusUrl,
            trustRoots: consensusTrustRoots,
            authorization: consensusAuthorization)
    }

    var fogView: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            attestation: attestation.fogView,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogMerkleProof: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            attestation: attestation.fogMerkleProof,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogKeyImage: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            attestation: attestation.fogKeyImage,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogBlock: ConnectionConfig<FogUrl> {
        ConnectionConfig(
            url: fogUrl,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogUntrustedTxOut: ConnectionConfig<FogUrl> {
        ConnectionConfig(
            url: fogUrl,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogReportAttestation: Attestation { attestation.fogReport }
}

extension NetworkConfig {
    struct AttestationConfig {
        let consensus: Attestation
        let fogView: Attestation
        let fogKeyImage: Attestation
        let fogMerkleProof: Attestation
        let fogReport: Attestation
    }
}
