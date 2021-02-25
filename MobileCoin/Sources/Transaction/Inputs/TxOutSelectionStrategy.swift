//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

protocol TxOutSelectionStrategy {
    func selectTxOuts(
        totalingAtLeast amount: UInt64,
        from txOuts: [KnownTxOut]
    ) throws -> [KnownTxOut]
}
