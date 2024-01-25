//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension AccountKey {
    public static func make(
        entropy: Data,
        fogReportUrl: String,
        fogReportId: String,
        fogAuthoritySpki: Data,
        accountIndex: UInt32 = 0
    ) -> Result<AccountKey, InvalidInputError> {
        Bip39Utils.mnemonic(fromEntropy: entropy).flatMap { mnemonic in
            make(
                mnemonic: mnemonic.phrase,
                fogReportUrl: fogReportUrl,
                fogReportId: fogReportId,
                fogAuthoritySpki: fogAuthoritySpki,
                accountIndex: accountIndex)
        }
    }

    public static func make(
        mnemonic: String,
        fogReportUrl: String,
        fogReportId: String,
        fogAuthoritySpki: Data,
        accountIndex: UInt32 = 0
    ) -> Result<AccountKey, InvalidInputError> {
        Slip10Utils.accountPrivateKeys(fromMnemonic: mnemonic, accountIndex: accountIndex)
            .flatMap {
                AccountKey.make(
                    viewPrivateKey: $0.viewPrivateKey,
                    spendPrivateKey: $0.spendPrivateKey,
                    fogReportUrl: fogReportUrl,
                    fogReportId: fogReportId,
                    fogAuthoritySpki: fogAuthoritySpki)
            }
    }

    init(
        mnemonic: Mnemonic,
        fogInfo: FogInfo? = nil,
        accountIndex: UInt32 = 0,
        subaddressIndex: UInt64 = McConstants.DEFAULT_SUBADDRESS_INDEX
    ) {
        let (viewPrivateKey, spendPrivateKey) =
            Slip10Utils.accountPrivateKeys(fromMnemonic: mnemonic, accountIndex: accountIndex)
        self.init(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            fogInfo: fogInfo,
            subaddressIndex: subaddressIndex)
    }
}
