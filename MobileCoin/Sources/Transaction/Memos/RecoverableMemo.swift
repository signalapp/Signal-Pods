//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum RecoveredMemo {
    case sender(SenderMemo)
    case destination(DestinationMemo)
    case senderWithPaymentRequest(SenderWithPaymentRequestMemo)
}

extension RecoveredMemo: Equatable { }

extension RecoveredMemo {
    var addressHash: AddressHash {
        switch self {
        case let .senderWithPaymentRequest(memo):
            return memo.addressHash
        case let .sender(memo):
            return memo.addressHash
        case let .destination(memo):
            return memo.addressHash
        }
    }
}

enum RecoverableMemo {
    case notset
    case unused
    case sender(RecoverableSenderMemo)
    case destination(RecoverableDestinationMemo)
    case senderWithPaymentRequest(RecoverableSenderWithPaymentRequestMemo)

    init(decryptedMemo data: Data66, accountKey: AccountKey, txOutKeys: TxOut.Keys) {
        guard let memoData = Data64(data[2...]) else {
            logger.fatalError("Should never be reached because the input data > 2 bytes")
        }
        let typeBytes = data[..<2]

        switch typeBytes.hexEncodedString() {
        case Types.SENDER_WITH_PAYMENT_REQUEST:
            let memo = RecoverableSenderWithPaymentRequestMemo(
                memoData,
                accountKey: accountKey,
                txOutPublicKey: txOutKeys.publicKey)
            self = .senderWithPaymentRequest(memo)
        case Types.SENDER:
            let memo = RecoverableSenderMemo(
                memoData,
                accountKey: accountKey,
                txOutPublicKey: txOutKeys.publicKey)
            self = .sender(memo)
        case Types.DESTINATION:
            let memo = RecoverableDestinationMemo(
                memoData,
                accountKey: accountKey,
                txOutKeys: txOutKeys)
            self = .destination(memo)
        case Types.UNUSED:
            self = .unused
        default:
            logger.warning("Memo data type unknown")
            self = .notset
        }
    }

    enum Types {
        static let SENDER = "0100"
        static let SENDER_WITH_PAYMENT_REQUEST = "0101"
        static let DESTINATION = "0200"
        static let UNUSED = "0000"
    }

    var isAuthenticatedSenderMemo: Bool {
        switch self {
        case .notset, .unused, .destination:
            return false
        case .sender, .senderWithPaymentRequest:
            return true
        }
    }

}

extension RecoverableMemo {
    func recover(publicAddress: PublicAddress) -> RecoveredMemo? {
        switch self {
        case .notset, .unused:
            return nil
        case let .destination(recoverable):
            guard let memo = recoverable.recover() else { return nil }
            return .destination(memo)
        case let .sender(recoverable):
            guard let memo = recoverable.recover(senderPublicAddress: publicAddress)
            else { return nil }
            return .sender(memo)
        case let .senderWithPaymentRequest(recoverable):
            guard let memo = recoverable.recover(senderPublicAddress: publicAddress)
            else { return nil }
            return .senderWithPaymentRequest(memo)
        }
    }
}

extension RecoverableMemo: Hashable { }

extension RecoverableMemo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.notset, .notset):
            return true
        case (.unused, .unused):
            return true
        case let (.sender(lhsMemo), .sender(rhsMemo)):
            return lhsMemo == rhsMemo
        case let (.destination(lhsMemo), .destination(rhsMemo)):
            return lhsMemo == rhsMemo
        case let (.senderWithPaymentRequest(lhsMemo), .senderWithPaymentRequest(rhsMemo)):
            return lhsMemo == rhsMemo
        default:
            return false
        }
    }
}

extension RecoverableMemo {
    func recover<Contact: PublicAddressProvider>(
        contacts: Set<Contact>
    ) -> (memo: RecoveredMemo?, contact: Contact?) {
        switch self {
        case let .destination(memo):
            guard let recoveredMemo = memo.recover() else {
                return (memo: nil, contact: nil)
            }
            guard let matchingContact = contacts.first(where: {
                    $0.publicAddress.calculateAddressHash() == recoveredMemo.addressHash
                })
            else {
                return (memo: .destination(recoveredMemo), contact: nil)
            }
            return (memo: .destination(recoveredMemo), contact: matchingContact)
        case .sender, .senderWithPaymentRequest:
            return contacts.compactMap { contact in
                guard let memo = self.recover(publicAddress: contact.publicAddress)
                else {
                    return nil
                }
                return (memo: memo, contact: contact)
            }
            .first ?? (memo: nil, contact: nil)
        case .notset, .unused:
            return (memo: nil, contact: nil)
        }
    }
}
