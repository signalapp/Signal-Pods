//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension SecCertificate {
    public func asPublicKey() -> Result<SecKey, SecurityError> {
        Self.publicKey(for: self)
    }

    public static func publicKey(for certificate: SecCertificate) -> Result<SecKey, SecurityError> {
        var publicKey: SecKey?
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate, policy, &trust)
        let data = certificate.data

        if let trust = trust, trustCreationStatus == errSecSuccess {
            publicKey = SecTrustCopyPublicKey(trust)
        } else {
            let message = "root certificate: \(data.base64EncodedString())"
            let error = SecurityError(trustCreationStatus, message: message)
            return .failure(error)
        }

        guard let key = publicKey else {
            let message = ", root certificate: \(data.base64EncodedString())"
            return .failure(SecurityError(nil, message: SecurityError.nilPublicKey + message))
        }

        return .success(key)
    }

    public var data: Data {
        SecCertificateCopyData(self) as Data
    }
}

extension Data {
    public func asSecCertificate() -> Result<SecCertificate, InvalidInputError> {
        Self.secCertificate(for: self)
    }

    public static func secCertificate(for data: Data) -> Result<SecCertificate, InvalidInputError> {
        let pinnedCertificateData = data as CFData
        if let pinnedCertificate = SecCertificateCreateWithData(nil, pinnedCertificateData) {
            return .success(pinnedCertificate)
        } else {
            let errorMessage = "Error parsing trust root certificate: " +
                "\(data.base64EncodedString())"
            logger.error(errorMessage, logFunction: false)
            return .failure(InvalidInputError(errorMessage))
        }
    }

    public static func pinnedCertificateKeys(for data: [Data]) -> Result<[SecKey], Error> {
        do {
            let keys = try data.map { bytes in
                try bytes.asSecCertificate().get()
            }
            .compactMap { cert in
                try SecCertificate.publicKey(for: cert).get()
            }
            return .success(keys)
        } catch {
            return .failure(error)
        }
    }
}

extension SecTrust {
    public var certificateCount: Int {
        SecTrustGetCertificateCount(self)
    }

    public var certificateTrustChain: [SecCertificate] {
        [Int](0..<certificateCount).compactMap {
            SecTrustGetCertificateAtIndex(self, $0)
        }
    }

    public var publicKeyTrustChain: [SecKey] {
        certificateTrustChain.compactMap {
            try? $0.asPublicKey().get()
        }
    }

    public var asPublicKeyTrustChain: Result<[SecKey], Error> {
        do {
            let keys = try certificateTrustChain.map {
                try $0.asPublicKey().get()
            }
            return .success(keys)
        } catch {
            return .failure(error)
        }
    }
}

extension SecKey {
    var data: Data? {
        SecKeyCopyExternalRepresentation(self, nil) as Data?
    }

}
