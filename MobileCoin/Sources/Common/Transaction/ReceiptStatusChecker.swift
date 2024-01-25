//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct ReceiptStatusChecker {
    private let account: ReadWriteDispatchLock<Account>

    init(account: ReadWriteDispatchLock<Account>) {
        self.account = account
    }

    func status(_ receipt: Receipt) -> Result<ReceiptStatus, InvalidInputError> {
        let result = account.readSync { $0.cachedReceivedStatus(of: receipt) }
            .map { ReceiptStatus($0) }
        logger.info(
            "Receipt status check complete. receipt.txOutPublicKey: " +
                "\(redacting: receipt.txOutPublicKey.hexEncodedString()), " +
                "receipt.txTombstoneBlockIndex: \(redacting: receipt.txTombstoneBlockIndex), " +
                "result: \(redacting: result)",
            logFunction: false)
        return result
    }
}
