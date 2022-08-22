//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

enum TxOutMemoParser {
    static let emptyEMemo = Data66()

    static func parse(
        encryptedPayload: Data66,
        accountKey: AccountKey,
        txOutKeys: TxOut.Keys
    ) -> RecoverableMemo {
        guard encryptedPayload != emptyEMemo,
              let decryptedMemo = TxOutUtils.decryptEMemoPayload(
                                                        encryptedMemo: encryptedPayload,
                                                        txOutPublicKey: txOutKeys.publicKey,
                                                        accountKey: accountKey)
        else {
            return .notset
        }

        return RecoverableMemo(
                        decryptedMemo: decryptedMemo,
                        accountKey: accountKey,
                        txOutKeys: txOutKeys)
    }

    static func parse(
        decryptedPayload: Data,
        accountKey: AccountKey,
        txOut: TxOutProtocol
    ) -> RecoverableMemo {
        guard let recoverableMemoPayload = Data66(decryptedPayload) else {
            logger.warning("Incorrect payload size for a recoverable memo")
            return .notset
        }
        return RecoverableMemo(
            decryptedMemo: recoverableMemoPayload,
            accountKey: accountKey,
            txOutKeys: txOut.keys)
    }
}
