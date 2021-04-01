//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct ReceiptStatusChecker {
    private let account: ReadWriteDispatchLock<Account>

    init(account: ReadWriteDispatchLock<Account>) {
        logger.info("")
        self.account = account
    }

    func status(_ receipt: Receipt) -> Result<ReceiptStatus, InvalidInputError> {
        receivedStatus(receipt).map { ReceiptStatus($0) }
    }

    func receivedStatus(_ receipt: Receipt) -> Result<Receipt.ReceivedStatus, InvalidInputError> {
        account.readSync { $0.cachedReceivedStatus(of: receipt) }
    }
}
