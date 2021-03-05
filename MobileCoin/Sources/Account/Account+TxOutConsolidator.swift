//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable todo

import Foundation

extension Account {
    struct TxOutConsolidator {
        private let serialQueue: DispatchQueue
        private let account: ReadWriteDispatchLock<Account>

        init(account: ReadWriteDispatchLock<Account>, targetQueue: DispatchQueue?) {
            self.serialQueue = DispatchQueue(
                label: "com.mobilecoin.\(Account.self).\(Self.self))",
                target: targetQueue)
            self.account = account
        }

        func consolidateTxOuts(completion: @escaping (Result<(), ConnectionError>) -> Void) {
            // TODO: Unimplemented
            serialQueue.async {
                completion(.success(()))
            }
        }
    }
}
