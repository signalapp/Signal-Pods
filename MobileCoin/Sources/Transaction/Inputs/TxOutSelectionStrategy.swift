//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

protocol TxOutSelectionStrategy {
    func selectTxOuts(_ txOuts: SpendableTxOutsWithAmount) -> SpendableTxOutsWithAmount
}
