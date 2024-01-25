//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum RecoveredMemo {
    case sender(SenderMemo)
    case destination(DestinationMemo)
    case destinationWithPaymentRequest(DestinationWithPaymentRequestMemo)
    case destinationWithPaymentIntent(DestinationWithPaymentIntentMemo)
    case senderWithPaymentRequest(SenderWithPaymentRequestMemo)
    case senderWithPaymentIntent(SenderWithPaymentIntentMemo)
}

extension RecoveredMemo: Equatable { }

extension RecoveredMemo {
    var addressHash: AddressHash {
        switch self {
        case let .senderWithPaymentRequest(memo):
            return memo.addressHash
        case let .senderWithPaymentIntent(memo):
            return memo.addressHash
        case let .sender(memo):
            return memo.addressHash
        case let .destinationWithPaymentRequest(memo):
            return memo.addressHash
        case let .destinationWithPaymentIntent(memo):
            return memo.addressHash
        case let .destination(memo):
            return memo.addressHash
        }
    }
}

public enum UnauthenticatedSenderMemo {
    case sender(SenderMemo)
    case senderWithPaymentRequest(SenderWithPaymentRequestMemo)
    case senderWithPaymentIntent(SenderWithPaymentIntentMemo)
}

extension UnauthenticatedSenderMemo: Equatable { }

extension UnauthenticatedSenderMemo {
    var addressHash: AddressHash {
        switch self {
        case let .senderWithPaymentRequest(memo):
            return memo.addressHash
        case let .senderWithPaymentIntent(memo):
            return memo.addressHash
        case let .sender(memo):
            return memo.addressHash
        }
    }
}

// swiftlint:disable function_body_length
enum RecoverableMemo {
    case notset
    case unused
    case sender(RecoverableSenderMemo)
    case destination(RecoverableDestinationMemo)
    case destinationWithPaymentRequest(RecoverableDestinationWithPaymentRequestMemo)
    case destinationWithPaymentIntent(RecoverableDestinationWithPaymentIntentMemo)
    case senderWithPaymentRequest(RecoverableSenderWithPaymentRequestMemo)
    case senderWithPaymentIntent(RecoverableSenderWithPaymentIntentMemo)

    init(decryptedMemo data: Data66, accountKey: AccountKey, txOutKeys: TxOut.Keys) {
        guard let memoData = Data64(data[2...]) else {
            logger.fatalError("Should never be reached because the input data > 2 bytes")
        }
        let typeBytes = data[..<2]

        switch typeBytes.hexEncodedString() {
        case SenderWithPaymentRequestMemo.type:
            let memo = RecoverableSenderWithPaymentRequestMemo(
                memoData,
                accountKey: accountKey,
                txOutPublicKey: txOutKeys.publicKey)
            self = .senderWithPaymentRequest(memo)
        case SenderWithPaymentIntentMemo.type:
            let memo = RecoverableSenderWithPaymentIntentMemo(
                memoData,
                accountKey: accountKey,
                txOutPublicKey: txOutKeys.publicKey)
            self = .senderWithPaymentIntent(memo)
        case SenderMemo.type:
            let memo = RecoverableSenderMemo(
                memoData,
                accountKey: accountKey,
                txOutPublicKey: txOutKeys.publicKey)
            self = .sender(memo)
        case DestinationMemo.type:
            let memo = RecoverableDestinationMemo(
                memoData,
                accountKey: accountKey,
                txOutKeys: txOutKeys)
            self = .destination(memo)
        case DestinationWithPaymentIntentMemo.type:
            let memo = RecoverableDestinationWithPaymentIntentMemo(
                memoData,
                accountKey: accountKey,
                txOutKeys: txOutKeys)
            self = .destinationWithPaymentIntent(memo)
        case DestinationWithPaymentRequestMemo.type:
            let memo = RecoverableDestinationWithPaymentRequestMemo(
                memoData,
                accountKey: accountKey,
                txOutKeys: txOutKeys)
            self = .destinationWithPaymentRequest(memo)
        case Self.UNUSED_TYPE:
            self = .unused
        default:
            logger.warning("Memo data type unknown")
            self = .notset
        }
    }

    static let UNUSED_TYPE = "0000"

    var isAuthenticatedSenderMemo: Bool {
        switch self {
        case .notset, .unused, .destination, .destinationWithPaymentIntent,
             .destinationWithPaymentRequest:
            return false
        case .sender, .senderWithPaymentRequest, .senderWithPaymentIntent:
            return true
        }
    }

}
// swiftlint:enable function_body_length

/// Memo Type "binary" header/prefixes and readable names
extension SenderMemo {
    public static let type = "0100"
    public static let typeName = "SenderMemo"
}

extension SenderWithPaymentRequestMemo {
    public static let type = "0101"
    public static let typeName = "SenderWithPaymentRequestIdMemo"
}

extension SenderWithPaymentIntentMemo {
    public static let type = "0102"
    public static let typeName = "SenderWithPaymentIntentIdMemo"
}

extension DestinationMemo {
    public static let type = "0200"
    public static let typeName = "DestinationMemo"
}

extension DestinationWithPaymentRequestMemo {
    public static let type = "0203"
    public static let typeName = "DestinationWithPaymentRequestIdMemo"
}

extension DestinationWithPaymentIntentMemo {
    public static let type = "0204"
    public static let typeName = "DestinationWithPaymentIntentIdMemo"
}

// swiftlint:disable cyclomatic_complexity
extension RecoverableMemo {
    func recover(publicAddress: PublicAddress? = nil) -> RecoveredMemo? {
        switch self {
        case .notset, .unused:
            return nil
        case let .destination(recoverable):
            guard let memo = recoverable.recover() else { return nil }
            return .destination(memo)
        case let .destinationWithPaymentIntent(recoverable):
            guard let memo = recoverable.recover() else { return nil }
            return .destinationWithPaymentIntent(memo)
        case let .destinationWithPaymentRequest(recoverable):
            guard let memo = recoverable.recover() else { return nil }
            return .destinationWithPaymentRequest(memo)
        case let .sender(recoverable):
            guard let publicAddress = publicAddress else { return nil }
            guard let memo = recoverable.recover(senderPublicAddress: publicAddress)
            else { return nil }
            return .sender(memo)
        case let .senderWithPaymentRequest(recoverable):
            guard let publicAddress = publicAddress else { return nil }
            guard let memo = recoverable.recover(senderPublicAddress: publicAddress)
            else { return nil }
            return .senderWithPaymentRequest(memo)
        case let .senderWithPaymentIntent(recoverable):
            guard let publicAddress = publicAddress else { return nil }
            guard let memo = recoverable.recover(senderPublicAddress: publicAddress)
            else { return nil }
            return .senderWithPaymentIntent(memo)
        }
    }
}
// swiftlint:enable cyclomatic_complexity

extension RecoverableMemo {
    func unauthenticatedSenderMemo() -> UnauthenticatedSenderMemo? {
        switch self {
        case .notset, .unused:
            return nil
        case .destination, .destinationWithPaymentIntent, .destinationWithPaymentRequest:
            assertionFailure(
                "This should not be called on destination memos because ..." +
                "Unauthenticated in this context means the txOut is not owned by the account")
            return nil
        case let .sender(recoverable):
            guard let memo = recoverable.unauthenticatedMemo()
            else { return nil }
            return .sender(memo)
        case let .senderWithPaymentRequest(recoverable):
            guard let memo = recoverable.unauthenticatedMemo()
            else { return nil }
            return .senderWithPaymentRequest(memo)
        case let .senderWithPaymentIntent(recoverable):
            guard let memo = recoverable.unauthenticatedMemo()
            else { return nil }
            return .senderWithPaymentIntent(memo)
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
    typealias RecoverResult = (
        memo: RecoveredMemo?,
        unauthenticated: UnauthenticatedSenderMemo?,
        contact: PublicAddressProvider?
    )

    func recover<Contact: PublicAddressProvider>(
        contacts: Set<Contact>
    ) -> RecoverResult {
        switch self {
        case .destination, .destinationWithPaymentIntent, .destinationWithPaymentRequest:
            guard let recoveredMemo = self.recover() else {
                return (memo: nil, unauthenticated: nil, contact: nil)
            }
            guard let matchingContact = contacts.first(where: {
                    $0.publicAddress.calculateAddressHash() == recoveredMemo.addressHash
                })
            else {
                return (memo: recoveredMemo, unauthenticated: nil, contact: nil)
            }
            return (memo: recoveredMemo, unauthenticated: nil, contact: matchingContact)
        case .sender, .senderWithPaymentRequest, .senderWithPaymentIntent:
            let recovered = contacts.compactMap { contact -> RecoverResult? in
                guard let memo = self.recover(publicAddress: contact.publicAddress)
                else {
                    return nil
                }
                return (memo: memo, unauthenticated:nil, contact: contact)
            }
            .first

            guard let recovered = recovered else {
                guard let unauthenticated = self.unauthenticatedSenderMemo() else {
                    return (memo: nil, unauthenticated: nil, contact: nil)
                }
                return (memo: nil, unauthenticated: unauthenticated, contact: nil)
            }
            return recovered
        case .notset, .unused:
            return (memo: nil, unauthenticated:nil, contact: nil)
        }
    }
}
