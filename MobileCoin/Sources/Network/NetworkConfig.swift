//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct NetworkConfig {
    static func make(consensusUrl: String, fogUrl: String, attestation: AttestationConfig, transportProtocol: TransportProtocol)
        -> Result<NetworkConfig, InvalidInputError>
    {
        ConsensusUrl.make(string: consensusUrl).flatMap { consensusUrl in
            FogUrl.make(string: fogUrl).map { fogUrl in
                NetworkConfig(consensusUrl: consensusUrl, fogUrl: fogUrl, attestation: attestation, transportProtocol: transportProtocol)
            }
        }
    }

    let consensusUrl: ConsensusUrl
    let fogUrl: FogUrl

    private let attestation: AttestationConfig

    var transportProtocol: TransportProtocol

    var consensusTrustRoots: [TransportProtocol: SSLCertificates] = [:]
    var fogTrustRoots: [TransportProtocol: SSLCertificates] = [:]

    var consensusAuthorization: BasicCredentials?
    var fogUserAuthorization: BasicCredentials?

    var httpRequester: HttpRequester? {
        didSet {
            httpRequester?.setFogTrustRoots(fogTrustRoots[.http] as? SecSSLCertificates)
            httpRequester?.setConsensusTrustRoots(consensusTrustRoots[.http] as? SecSSLCertificates)
        }
    }
    
    init(consensusUrl: ConsensusUrl, fogUrl: FogUrl, attestation: AttestationConfig, transportProtocol: TransportProtocol) {
        self.consensusUrl = consensusUrl
        self.fogUrl = fogUrl
        self.attestation = attestation
        self.transportProtocol = transportProtocol
    }

    var consensus: AttestedConnectionConfig<ConsensusUrl> {
        AttestedConnectionConfig(
            url: consensusUrl,
            transportProtocolOption: transportProtocol.option,
            attestation: attestation.consensus,
            trustRoots: consensusTrustRoots,
            authorization: consensusAuthorization)
    }

    var blockchain: ConnectionConfig<ConsensusUrl> {
        ConnectionConfig(
            url: consensusUrl,
            transportProtocolOption: transportProtocol.option,
            trustRoots: consensusTrustRoots,
            authorization: consensusAuthorization)
    }

    var fogView: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            transportProtocolOption: transportProtocol.option,
            attestation: attestation.fogView,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogMerkleProof: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            transportProtocolOption: transportProtocol.option,
            attestation: attestation.fogMerkleProof,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogKeyImage: AttestedConnectionConfig<FogUrl> {
        AttestedConnectionConfig(
            url: fogUrl,
            transportProtocolOption: transportProtocol.option,
            attestation: attestation.fogKeyImage,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogBlock: ConnectionConfig<FogUrl> {
        ConnectionConfig(
            url: fogUrl,
            transportProtocolOption: transportProtocol.option,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogUntrustedTxOut: ConnectionConfig<FogUrl> {
        ConnectionConfig(
            url: fogUrl,
            transportProtocolOption: transportProtocol.option,
            trustRoots: fogTrustRoots,
            authorization: fogUserAuthorization)
    }

    var fogReportAttestation: Attestation { attestation.fogReport }
    
    @discardableResult mutating public func setConsensusTrustRoots(_ trustRoots: [Data])
        -> Result<(), InvalidInputError>
    {
        let (grpc, http) = validatedCertificates(trustRoots)
        
        self.consensusTrustRoots[.grpc] = try? grpc.get()
        self.consensusTrustRoots[.http] = try? http.get()
        self.httpRequester?.setConsensusTrustRoots(try? http.get() as? SecSSLCertificates)
        
        return currentProtocolValidation(grpc: grpc, http: http)
    }
    
    @discardableResult mutating public func setFogTrustRoots(_ trustRoots: [Data])
        -> Result<(), InvalidInputError>
    {
        let (grpc, http) = validatedCertificates(trustRoots)
        
        self.fogTrustRoots[.grpc] = try? grpc.get()
        self.fogTrustRoots[.http] = try? http.get()
        self.httpRequester?.setFogTrustRoots(try? http.get() as? SecSSLCertificates)
        
        return currentProtocolValidation(grpc: grpc, http: http)
    }
    
    private typealias PossibleCertificates = Result<SSLCertificates, InvalidInputError>
    private func validatedCertificates(_ trustRoots: [Data]) -> (grpc: PossibleCertificates, http:PossibleCertificates) {
        let grpc = TransportProtocol.grpc.certificateValidator.validate(trustRoots)
        let http = TransportProtocol.http.certificateValidator.validate(trustRoots)
        return (grpc, http)
    }
    
    private func currentProtocolValidation(grpc: PossibleCertificates, http: PossibleCertificates)
        -> Result<(), InvalidInputError>
    {
        switch (transportProtocol, grpc, http) {
        case (.grpc, .success( _), _):
            return .success(())
        case (.grpc, .failure(let error), _):
            return .failure(error)
        case (.http, _, .success( _)):
            return .success(())
        case (.http, _, .failure(let error)):
            return .failure(error)
        case (_, _, _):
            return .failure(InvalidInputError("Empty certificates"))
        }
    }
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
