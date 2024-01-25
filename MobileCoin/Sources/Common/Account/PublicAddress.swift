//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public struct PublicAddress {
    static func make(
        viewPublicKey: RistrettoPublic,
        spendPublicKey: RistrettoPublic,
        fogReportUrl: String,
        fogReportId: String,
        fogAuthoritySig: Data
    ) -> Result<PublicAddress, InvalidInputError> {
        FogInfo.make(
            reportUrl: fogReportUrl,
            reportId: fogReportId,
            authoritySig: fogAuthoritySig)
            .map { fogInfo in
                PublicAddress(
                    viewPublicKey: viewPublicKey,
                    spendPublicKey: spendPublicKey,
                    fogInfo: fogInfo)
            }
    }

    let viewPublicKeyTyped: RistrettoPublic
    let spendPublicKeyTyped: RistrettoPublic
    let fogInfo: FogInfo?

    init(viewPublicKey: RistrettoPublic, spendPublicKey: RistrettoPublic, fogInfo: FogInfo? = nil) {
        self.viewPublicKeyTyped = viewPublicKey
        self.spendPublicKeyTyped = spendPublicKey
        self.fogInfo = fogInfo
    }

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_PublicAddress(serializedData: serializedData) else {
            logger.warning("External_PublicAddress deserialization failed. serializedData: " +
                "\(redacting: serializedData.base64EncodedString())")
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        let proto = External_PublicAddress(self)
        return proto.serializedDataInfallible
    }

    /// Subaddress view public key, `C`, in bytes.
    public var viewPublicKey: Data { viewPublicKeyTyped.data }

    /// Subaddress spend public key, `D`, in bytes.
    public var spendPublicKey: Data { spendPublicKeyTyped.data }

    public var fogReportUrlString: String? { fogInfo?.reportUrlString }

    public var addressHash: Data? { calculateAddressHash()?.data }

    var fogReportUrl: FogUrl? { fogInfo?.reportUrl }
    var fogReportId: String? { fogInfo?.reportId }
    var fogAuthoritySig: Data? { fogInfo?.authoritySig }
}

extension PublicAddress: Equatable {}
extension PublicAddress: Hashable {}

extension PublicAddress: CustomRedactingStringConvertible {
    var redactingDescription: String {
        "PublicAddress(\(Base58Coder.encode(self)))"
    }
}

extension PublicAddress {
    init(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        accountKeyFogInfo: AccountKey.FogInfo? = nil,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        let (viewPublicKey, spendPublicKey) = AccountKeyUtils.publicAddressPublicKeys(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            subaddressIndex: subaddressIndex)

        let fogInfo: FogInfo?
        if let accountKeyFogInfo = accountKeyFogInfo {
            fogInfo = FogInfo(
                viewPrivateKey: viewPrivateKey,
                spendPrivateKey: spendPrivateKey,
                accountKeyFogInfo: accountKeyFogInfo,
                subaddressIndex: subaddressIndex)
        } else {
            fogInfo = nil
        }

        self.init(viewPublicKey: viewPublicKey, spendPublicKey: spendPublicKey, fogInfo: fogInfo)
    }
}

extension PublicAddress {
    init?(_ publicAddress: External_PublicAddress) {
        guard let viewPublicKey = RistrettoPublic(publicAddress.viewPublicKey),
              let spendPublicKey = RistrettoPublic(publicAddress.spendPublicKey)
        else {
            return nil
        }

        let fogInfo: FogInfo?
        if !publicAddress.fogReportURL.isEmpty {
            guard case .success(let maybeFogInfo) = FogInfo.make(
                reportUrl: publicAddress.fogReportURL,
                reportId: publicAddress.fogReportID,
                authoritySig: publicAddress.fogAuthoritySig)
            else {
                return nil
            }
            fogInfo = maybeFogInfo
        } else {
            fogInfo = nil
        }

        self.init(viewPublicKey: viewPublicKey, spendPublicKey: spendPublicKey, fogInfo: fogInfo)
    }
}

extension External_PublicAddress {
    init(_ publicAddress: PublicAddress) {
        self.init()
        self.viewPublicKey = External_CompressedRistretto(publicAddress.viewPublicKey)
        self.spendPublicKey = External_CompressedRistretto(publicAddress.spendPublicKey)
        if let fogInfo = publicAddress.fogInfo {
            self.fogReportURL = fogInfo.reportUrlString
            self.fogReportID = fogInfo.reportId
            self.fogAuthoritySig = fogInfo.authoritySig
        }
    }
}

extension PublicAddress {
    func calculateAddressHash() -> AddressHash? {
        AccountKeyUtils.publicAddressShortHash(publicAddress: self)
    }
}

extension PublicAddress {
    struct FogInfo {
        fileprivate static func make(reportUrl: String, reportId: String, authoritySig: Data)
            -> Result<FogInfo, InvalidInputError>
        {
            FogUrl.make(string: reportUrl).map { reportUrlTyped in
                FogInfo(
                    reportUrlString: reportUrl,
                    reportUrl: reportUrlTyped,
                    reportId: reportId,
                    authoritySig: authoritySig)
            }
        }

        let reportUrlString: String
        let reportUrl: FogUrl
        let reportId: String
        let authoritySig: Data

        private init(
            reportUrlString: String,
            reportUrl: FogUrl,
            reportId: String,
            authoritySig: Data
        ) {
            self.reportUrlString = reportUrlString
            self.reportUrl = reportUrl
            self.reportId = reportId
            self.authoritySig = authoritySig
        }
    }
}

extension PublicAddress.FogInfo: Equatable {}
extension PublicAddress.FogInfo: Hashable {}

extension PublicAddress.FogInfo {
    fileprivate init(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        accountKeyFogInfo: AccountKey.FogInfo,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        let authoritySig = AccountKeyUtils.fogAuthoritySig(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            reportUrl: accountKeyFogInfo.reportUrlString,
            reportId: accountKeyFogInfo.reportId,
            authoritySpki: accountKeyFogInfo.authoritySpki,
            subaddressIndex: subaddressIndex)
        self.init(
            reportUrlString: accountKeyFogInfo.reportUrlString,
            reportUrl: accountKeyFogInfo.reportUrl,
            reportId: accountKeyFogInfo.reportId,
            authoritySig: authoritySig)
    }
}
