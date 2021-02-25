//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

public struct AccountKey {
    let viewPrivateKey: RistrettoPrivate
    let spendPrivateKey: RistrettoPrivate
    let fogInfo: FogInfo?
    let subaddressIndex: UInt64

    public let publicAddress: PublicAddress

    public static func make(
        rootEntropy: Data,
        fogReportUrl: String,
        fogAuthoritySpki: Data,
        fogReportId: String
    ) -> Result<AccountKey, MalformedInput> {
        guard let rootEntropy = Data32(rootEntropy) else {
            return .failure(MalformedInput("rootEntropy must be 32 bytes in length"))
        }

        let fogReportUrlTyped: FogReportUrl
        do {
            fogReportUrlTyped = try FogReportUrl(string: fogReportUrl)
        } catch {
            return .failure(MalformedInput(String(describing: error)))
        }

        let fogInfo = FogInfo(
            reportUrlString: fogReportUrl,
            reportUrl: fogReportUrlTyped,
            authoritySpki: fogAuthoritySpki,
            reportId: fogReportId)
        return .success(Self(rootEntropy: rootEntropy, fogInfo: fogInfo))
    }

    @available(*, deprecated,
        renamed: "AccountKey.make(rootEntropy:fogReportUrl:fogAuthoritySpki:fogReportId:)")
    public static func make(
        rootEntropy: Data,
        fogReportUrl: String,
        fogAuthorityFingerprint: Data,
        fogReportId: String
    ) -> Result<AccountKey, MalformedInput> {
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
        let result = Self.make(
            rootEntropy: rootEntropy,
            fogReportUrl: fogReportUrl,
            fogAuthoritySpki: fogAuthorityFingerprint,
            fogReportId: fogReportId)
        self = try result.get()
    }

    init(
        rootEntropy: Data32,
        fogReportUrl: String,
        fogAuthoritySpki: Data,
        fogReportId: String,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) throws {
        let fogInfo = try FogInfo(
            reportUrl: fogReportUrl,
            authoritySpki: fogAuthoritySpki,
            reportId: fogReportId)
        self.init(rootEntropy: rootEntropy, fogInfo: fogInfo, subaddressIndex: subaddressIndex)
    }

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
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            fatalError("Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
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
    init?(
        _ proto: External_AccountKey,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        guard let viewPrivateKey = RistrettoPrivate(proto.viewPrivateKey.data),
              let spendPrivateKey = RistrettoPrivate(proto.spendPrivateKey.data)
        else {
            return nil
        }

        let fogInfo: FogInfo?
        if !proto.fogReportURL.isEmpty {
            guard let maybeFogInfo = try? FogInfo(
                reportUrl: proto.fogReportURL,
                authoritySpki: proto.fogAuthoritySpki,
                reportId: proto.fogReportID)
            else {
                return nil
            }
            fogInfo = maybeFogInfo
        } else {
            fogInfo = nil
        }

        self.init(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            fogInfo: fogInfo,
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
        let reportUrlString: String
        let reportUrl: FogReportUrl
        let authoritySpki: Data
        let reportId: String

        fileprivate init(
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

        fileprivate init(reportUrl: String, authoritySpki: Data, reportId: String) throws {
            self.reportUrlString = reportUrl
            self.reportUrl = try FogReportUrl(string: reportUrl)
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
        guard accountKey.fogReportUrl != nil else {
            return nil
        }

        self.accountKey = accountKey
    }
}
