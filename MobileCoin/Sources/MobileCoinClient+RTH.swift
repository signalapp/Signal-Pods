//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension MobileCoinClient {

    static func recover<Contact: PublicAddressProvider>(
        txOut: OwnedTxOut,
        contacts: Set<Contact>
    ) -> HistoricalTransaction where Contact: Hashable {
        let (memo, unauthenticated, contact) = txOut.recoverableMemo.recover(contacts: contacts)
        return HistoricalTransaction(
            memo: memo,
            unauthenticatedMemo: unauthenticated,
            txOut: txOut,
            contact: contact)
    }

    static public func recoverTransactions<Contact: PublicAddressProvider>(
        _ transactions: Set<OwnedTxOut>,
        contacts: Set<Contact>
    ) -> [HistoricalTransaction] where Contact: Hashable {
        transactions.map { txOut in
            Self.recover(txOut: txOut, contacts: contacts)
        }
        .sorted { lhs, rhs in
            lhs.txOut.receivedBlock.index < rhs.txOut.receivedBlock.index
        }
    }

}
