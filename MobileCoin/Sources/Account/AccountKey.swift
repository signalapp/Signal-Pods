//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

public struct AccountKey {
    static func make(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        fogReportUrl: String,
        fogReportId: String,
        fogAuthoritySpki: Data,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) -> Result<AccountKey, InvalidInputError> {
        FogInfo.make(
            reportUrl: fogReportUrl,
            reportId: fogReportId,
            authoritySpki: fogAuthoritySpki
        ).map { fogInfo in
            AccountKey(
                viewPrivateKey: viewPrivateKey,
                spendPrivateKey: spendPrivateKey,
                fogInfo: fogInfo,
                subaddressIndex: subaddressIndex)
        }
    }

    let viewPrivateKey: RistrettoPrivate
    let spendPrivateKey: RistrettoPrivate
    let fogInfo: FogInfo?
    let subaddressIndex: UInt64

    public let publicAddress: PublicAddress

    init(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        fogInfo: FogInfo? = nil,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        self.viewPrivateKey = viewPrivateKey
        self.spendPrivateKey = spendPrivateKey
        self.fogInfo = fogInfo
        self.subaddressIndex = subaddressIndex
        self.publicAddress = PublicAddress(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            accountKeyFogInfo: fogInfo,
            subaddressIndex: subaddressIndex)
    }

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_AccountKey(serializedData: serializedData) else {
            logger.warning("External_AccountKey deserialization failed.")
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        let proto = External_AccountKey(self)
        do {
            return try proto.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError("Protobuf serialization failed: \(redacting: error)")
        }
    }

    var fogReportUrlString: String? { fogInfo?.reportUrlString }
    var fogReportUrl: FogUrl? { fogInfo?.reportUrl }
    var fogReportId: String? { fogInfo?.reportId }
    var fogAuthoritySpki: Data? { fogInfo?.authoritySpki }

    var subaddressViewPrivateKey: RistrettoPrivate {
        AccountKeyUtils.subaddressPrivateKeys(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            subaddressIndex: subaddressIndex
        ).subaddressViewPrivateKey
    }

    var subaddressSpendPrivateKey: RistrettoPrivate {
        AccountKeyUtils.subaddressPrivateKeys(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            subaddressIndex: subaddressIndex
        ).subaddressSpendPrivateKey
    }
}

extension AccountKey: Equatable {}
extension AccountKey: Hashable {}

extension AccountKey {
    init?(
        _ proto: External_AccountKey,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        guard let viewPrivateKey = RistrettoPrivate(proto.viewPrivateKey.data),
              let spendPrivateKey = RistrettoPrivate(proto.spendPrivateKey.data)
        else {
            return nil
        }

        let maybeFogInfo: FogInfo?
        if !proto.fogReportURL.isEmpty {
            guard case .success(let fogInfo) = FogInfo.make(
                reportUrl: proto.fogReportURL,
                reportId: proto.fogReportID,
                authoritySpki: proto.fogAuthoritySpki)
            else {
                return nil
            }
            maybeFogInfo = fogInfo
        } else {
            maybeFogInfo = nil
        }

        self.init(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            fogInfo: maybeFogInfo,
            subaddressIndex: subaddressIndex)
    }
}

extension External_AccountKey {
    init(_ accountKey: AccountKey) {
        self.init()
        self.viewPrivateKey = External_RistrettoPrivate(accountKey.viewPrivateKey)
        self.spendPrivateKey = External_RistrettoPrivate(accountKey.spendPrivateKey)
        if let fogInfo = accountKey.fogInfo {
            self.fogReportURL = fogInfo.reportUrlString
            self.fogReportID = fogInfo.reportId
            self.fogAuthoritySpki = fogInfo.authoritySpki
        }
    }
}

extension AccountKey {
    struct FogInfo {
        fileprivate static func make(reportUrl: String, reportId: String, authoritySpki: Data)
            -> Result<FogInfo, InvalidInputError>
        {
            FogUrl.make(string: reportUrl).map { reportUrlTyped in
                FogInfo(
                    reportUrlString: reportUrl,
                    reportUrl: reportUrlTyped,
                    reportId: reportId,
                    authoritySpki: authoritySpki)
            }
        }

        let reportUrlString: String
        let reportUrl: FogUrl
        let reportId: String
        let authoritySpki: Data

        private init(
            reportUrlString: String,
            reportUrl: FogUrl,
            reportId: String,
            authoritySpki: Data
        ) {
            self.reportUrlString = reportUrlString
            self.reportUrl = reportUrl
            self.reportId = reportId
            self.authoritySpki = authoritySpki
        }
    }
}

extension AccountKey.FogInfo: Equatable {}
extension AccountKey.FogInfo: Hashable {}

struct AccountKeyWithFog {
    let accountKey: AccountKey

    init?(accountKey: AccountKey) {
        guard accountKey.fogInfo != nil else {
            return nil
        }
        self.accountKey = accountKey
    }

    var fogInfo: AccountKey.FogInfo {
        guard let fogInfo = accountKey.fogInfo else {
            // Safety: accountKey is guaranteed to have fogInfo.
            logger.fatalError("accountKey doesn't have fogInfo")
        }
        return fogInfo
    }
}
