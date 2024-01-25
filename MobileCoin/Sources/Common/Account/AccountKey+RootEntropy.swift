//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension AccountKey {
    public static func make(
        rootEntropy: Data,
        fogReportUrl: String,
        fogReportId: String,
        fogAuthoritySpki: Data
    ) -> Result<AccountKey, InvalidInputError> {
        let keys = RootEntropyUtils.privateKeys(fromEntropy: rootEntropy)
        return AccountKey.make(
            viewPrivateKey: keys.viewPrivateKey,
            spendPrivateKey: keys.spendPrivateKey,
            fogReportUrl: fogReportUrl,
            fogReportId: fogReportId,
            fogAuthoritySpki: fogAuthoritySpki)
    }
}
