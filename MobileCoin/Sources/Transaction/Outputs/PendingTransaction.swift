//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct PendingTransaction {
    public let transaction: Transaction
    public let payloadTxOutContexts: [TxOutContext]
    public var changeTxOutContext: TxOutContext

    public var receipts: [Receipt] {
        (payloadTxOutContexts + [changeTxOutContext]).map({
            $0.receipt
        })
    }

    var singlePayload: PendingSinglePayloadTransaction {
        PendingSinglePayloadTransaction(
            transaction: transaction,
            payloadTxOutContext: payloadTxOutContexts[0],
            changeTxOutContext: changeTxOutContext)
    }
}

public struct PendingSinglePayloadTransaction {
    public let transaction: Transaction
    public let payloadTxOutContext: TxOutContext
    public var changeTxOutContext: TxOutContext

    public var receipt: Receipt {
        payloadTxOutContext.receipt
    }
}

extension PendingTransaction: Equatable, Hashable {}
