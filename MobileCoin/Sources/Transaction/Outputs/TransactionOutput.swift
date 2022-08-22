//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct TransactionOutput {
    let recipient: PublicAddress
    let amount: PositiveUInt64
}

extension TransactionOutput: Equatable, Hashable {}

extension TransactionOutput {
    init(_ recipient: PublicAddress, _ amount: PositiveUInt64) {
        self.recipient = recipient
        self.amount = amount
    }
}
