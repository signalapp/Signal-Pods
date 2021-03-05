//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

public struct PublicAddress {
    static func make(
        viewPublicKey: RistrettoPublic,
        spendPublicKey: RistrettoPublic,
        fogReportUrl: String,
        fogAuthoritySig: Data,
        fogReportId: String
    ) -> Result<PublicAddress, InvalidInputError> {
        FogInfo.make(reportUrl: fogReportUrl, authoritySig: fogAuthoritySig, reportId: fogReportId)
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
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        let proto = External_PublicAddress(self)
        do {
            return try proto.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError(
                "Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }
    }

    /// Subaddress view public key, `C`, in bytes.
    public var viewPublicKey: Data { viewPublicKeyTyped.data }

    /// Subaddress spend public key, `D`, in bytes.
    public var spendPublicKey: Data { spendPublicKeyTyped.data }

    public var fogReportUrlString: String? { fogInfo?.reportUrlString }

    var fogReportUrl: FogReportUrl? { fogInfo?.reportUrl }
    var fogAuthoritySig: Data? { fogInfo?.authoritySig }
    var fogReportId: String? { fogInfo?.reportId }
}

extension PublicAddress: Equatable {}
extension PublicAddress: Hashable {}

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
        guard let viewPublicKey = RistrettoPublic(publicAddress.viewPublicKey.data),
              let spendPublicKey = RistrettoPublic(publicAddress.spendPublicKey.data)
        else {
            return nil
        }

        let fogInfo: FogInfo?
        if !publicAddress.fogReportURL.isEmpty {
            guard case .success(let maybeFogInfo) = FogInfo.make(
                reportUrl: publicAddress.fogReportURL,
                authoritySig: publicAddress.fogAuthoritySig,
                reportId: publicAddress.fogReportID)
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
    struct FogInfo {
        fileprivate static func make(reportUrl: String, authoritySig: Data, reportId: String)
            -> Result<FogInfo, InvalidInputError>
        {
            FogReportUrl.make(string: reportUrl).map { reportUrlTyped in
                FogInfo(
                    reportUrlString: reportUrl,
                    reportUrl: reportUrlTyped,
                    authoritySig: authoritySig,
                    reportId: reportId)
            }
        }

        let reportUrlString: String
        let reportUrl: FogReportUrl
        let authoritySig: Data
        let reportId: String

        private init(
            reportUrlString: String,
            reportUrl: FogReportUrl,
            authoritySig: Data,
            reportId: String
        ) {
            self.reportUrlString = reportUrlString
            self.reportUrl = reportUrl
            self.authoritySig = authoritySig
            self.reportId = reportId
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
            authoritySig: authoritySig,
            reportId: accountKeyFogInfo.reportId)
    }
}
