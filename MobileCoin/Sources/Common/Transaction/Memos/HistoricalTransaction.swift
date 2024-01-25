//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct HistoricalTransaction {
    public let memo: RecoveredMemo?
    public let unauthenticatedMemo: UnauthenticatedSenderMemo?
    public let txOut: OwnedTxOut
    public let contact: PublicAddressProvider?
}

extension HistoricalTransaction {
    init(txOut: OwnedTxOut) {
        self.memo = nil
        self.unauthenticatedMemo = nil
        self.contact = nil
        self.txOut = txOut
    }
}
