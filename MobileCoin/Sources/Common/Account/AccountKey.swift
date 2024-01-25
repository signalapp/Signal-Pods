//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

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
    let changeSubaddressIndex: UInt64

    let subaddressPrivateKeys: SubaddressPrivateKeys
    let changeSubaddressPrivateKeys: SubaddressPrivateKeys

    public let publicAddress: PublicAddress
    public let publicChangeAddress: PublicAddress

    init(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        fogInfo: FogInfo? = nil,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX,
        changeSubaddressIndex: UInt64 = McConstants.DEFAULT_CHANGE_SUBADDRESS_INDEX
    ) {
        self.viewPrivateKey = viewPrivateKey
        self.spendPrivateKey = spendPrivateKey
        self.fogInfo = fogInfo
        self.subaddressIndex = subaddressIndex
        self.changeSubaddressIndex = changeSubaddressIndex
        self.publicAddress = PublicAddress(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            accountKeyFogInfo: fogInfo,
            subaddressIndex: subaddressIndex)
        self.publicChangeAddress = PublicAddress(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            accountKeyFogInfo: fogInfo,
            subaddressIndex: changeSubaddressIndex)
        self.subaddressPrivateKeys = Self.makeSubaddressPrivateKeys(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            subaddressIndex: subaddressIndex)
        self.changeSubaddressPrivateKeys = Self.makeSubaddressPrivateKeys(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            subaddressIndex: changeSubaddressIndex)
    }

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_AccountKey(serializedData: serializedData) else {
            logger.error("External_AccountKey deserialization failed.", logFunction: false)
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        let proto = External_AccountKey(self)
        return proto.serializedDataInfallible
    }

    var fogReportUrlString: String? { fogInfo?.reportUrlString }
    var fogReportUrl: FogUrl? { fogInfo?.reportUrl }
    var fogReportId: String? { fogInfo?.reportId }
    var fogAuthoritySpki: Data? { fogInfo?.authoritySpki }

    var subaddressViewPrivateKey: RistrettoPrivate { subaddressPrivateKeys.viewKey }
    var subaddressSpendPrivateKey: RistrettoPrivate { subaddressPrivateKeys.spendKey }
    var changeSubaddressViewPrivateKey: RistrettoPrivate { changeSubaddressPrivateKeys.viewKey }
    var changeSubaddressSpendPrivateKey: RistrettoPrivate { changeSubaddressPrivateKeys.spendKey }

    private var indexedPrivateKeys: [UInt64: SubaddressPrivateKeys] {
        [
            subaddressIndex: subaddressPrivateKeys,
            changeSubaddressIndex: changeSubaddressPrivateKeys,
        ]
    }

    func subaddressSpendPrivateKey(index: UInt64) -> RistrettoPrivate? {
        indexedPrivateKeys[index]?.spendKey
    }

    func subaddressViewPrivateKey(index: UInt64) -> RistrettoPrivate? {
        indexedPrivateKeys[index]?.viewKey
    }

    func privateKeys(for index: UInt64) -> SubaddressPrivateKeys? {
        indexedPrivateKeys[index]
    }
}

extension AccountKey: Equatable {}
extension AccountKey: Hashable {}

extension AccountKey {
    struct SubaddressPrivateKeys {
        let viewKey: RistrettoPrivate
        let spendKey: RistrettoPrivate
    }

    static func makeSubaddressPrivateKeys(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        subaddressIndex: UInt64
    ) -> SubaddressPrivateKeys {
        let keys = AccountKeyUtils.subaddressPrivateKeys(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            subaddressIndex: subaddressIndex)
        return  SubaddressPrivateKeys(viewKey: keys.viewKey, spendKey: keys.spendKey)
    }
}

extension AccountKey.SubaddressPrivateKeys: Equatable, Hashable {}

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
    let fogInfo: AccountKey.FogInfo

    init?(accountKey: AccountKey) {
        guard let fogInfo = accountKey.fogInfo else {
            return nil
        }

        self.accountKey = accountKey
        self.fogInfo = fogInfo
    }
}
