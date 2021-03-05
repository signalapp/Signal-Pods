//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

public struct AccountKey {
    public static func make(
        rootEntropy: Data,
        fogReportUrl: String,
        fogAuthoritySpki: Data,
        fogReportId: String
    ) -> Result<AccountKey, InvalidInputError> {
        guard let rootEntropy = Data32(rootEntropy) else {
            return .failure(InvalidInputError("rootEntropy must be 32 bytes in length"))
        }

        return FogInfo.make(
            reportUrl: fogReportUrl,
            authoritySpki: fogAuthoritySpki,
            reportId: fogReportId
        ).map { fogInfo in
            AccountKey(rootEntropy: rootEntropy, fogInfo: fogInfo)
        }
    }

    static func make(
        rootEntropy: Data32,
        fogReportUrl: String,
        fogAuthoritySpki: Data,
        fogReportId: String,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) -> Result<AccountKey, InvalidInputError> {
        FogInfo.make(
            reportUrl: fogReportUrl,
            authoritySpki: fogAuthoritySpki,
            reportId: fogReportId
        ).map { fogInfo in
            AccountKey(
                rootEntropy: rootEntropy,
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
        rootEntropy: Data32,
        fogInfo: FogInfo? = nil,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        let (viewPrivateKey, spendPrivateKey) = AccountKeyUtils.privateKeys(
            fromRootEntropy: rootEntropy)
        self.init(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            fogInfo: fogInfo,
            subaddressIndex: subaddressIndex)
    }

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
            logger.fatalError(
                "Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }
    }

    var fogReportUrlString: String? { fogInfo?.reportUrlString }
    var fogReportUrl: FogReportUrl? { fogInfo?.reportUrl }
    var fogAuthoritySpki: Data? { fogInfo?.authoritySpki }
    var fogReportId: String? { fogInfo?.reportId }

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
    @available(*, deprecated,
        renamed: "AccountKey.make(rootEntropy:fogReportUrl:fogAuthoritySpki:fogReportId:)")
    public static func make(
        rootEntropy: Data,
        fogReportUrl: String,
        fogAuthorityFingerprint: Data,
        fogReportId: String
    ) -> Result<AccountKey, InvalidInputError> {
        make(
            rootEntropy: rootEntropy,
            fogReportUrl: fogReportUrl,
            fogAuthoritySpki: fogAuthorityFingerprint,
            fogReportId: fogReportId)
    }

    @available(*, deprecated,
        renamed: "AccountKey.make(rootEntropy:fogReportUrl:fogAuthoritySpki:fogReportId:)")
    public init(
        rootEntropy: Data,
        fogReportUrl: String,
        fogAuthorityFingerprint: Data,
        fogReportId: String
    ) throws {
        let result = AccountKey.make(
            rootEntropy: rootEntropy,
            fogReportUrl: fogReportUrl,
            fogAuthoritySpki: fogAuthorityFingerprint,
            fogReportId: fogReportId)
        self = try result.get()
    }
}

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
                authoritySpki: proto.fogAuthoritySpki,
                reportId: proto.fogReportID)
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
        fileprivate static func make(reportUrl: String, authoritySpki: Data, reportId: String)
            -> Result<FogInfo, InvalidInputError>
        {
            FogReportUrl.make(string: reportUrl).map { reportUrlTyped in
                FogInfo(
                    reportUrlString: reportUrl,
                    reportUrl: reportUrlTyped,
                    authoritySpki: authoritySpki,
                    reportId: reportId)
            }
        }

        let reportUrlString: String
        let reportUrl: FogReportUrl
        let authoritySpki: Data
        let reportId: String

        private init(
            reportUrlString: String,
            reportUrl: FogReportUrl,
            authoritySpki: Data,
            reportId: String
        ) {
            self.reportUrlString = reportUrlString
            self.reportUrl = reportUrl
            self.authoritySpki = authoritySpki
            self.reportId = reportId
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
            logger.fatalError("\(Self.self).\(#function): accountKey doesn't have fogInfo.")
        }

        return fogInfo
    }
}
