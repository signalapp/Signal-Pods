//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public enum MemoType {
    case unused
    case recoverable
    case customRecoverable(sender: AccountKey)
    case recoverablePaymentRequest(id: UInt64)
    case customPaymentRequest(sender: AccountKey, id: UInt64)
    case recoverablePaymentIntent(id: UInt64)
    case customPaymentIntent(sender: AccountKey, id: UInt64)

    func createMemoBuilder(accountKey: AccountKey) -> TxOutMemoBuilder {
        switch self {
        case .unused:
            return TxOutMemoBuilder.createDefaultMemoBuilder()
        case .recoverable:
            return TxOutMemoBuilder.createRecoverableMemoBuilder(accountKey: accountKey)
        case .customRecoverable(let sender):
            return TxOutMemoBuilder.createRecoverableMemoBuilder(accountKey: sender)
        case .recoverablePaymentRequest(let id):
            return TxOutMemoBuilder.createRecoverablePaymentRequestMemoBuilder(
                paymentRequestId: id,
                accountKey: accountKey)
        case let .customPaymentRequest(sender, id):
            return TxOutMemoBuilder.createRecoverablePaymentRequestMemoBuilder(
                paymentRequestId: id,
                accountKey: sender)
        case .recoverablePaymentIntent(let id):
            return TxOutMemoBuilder.createRecoverablePaymentIntentMemoBuilder(
                paymentIntentId: id,
                accountKey: accountKey)
        case let .customPaymentIntent(sender, id):
            return TxOutMemoBuilder.createRecoverablePaymentIntentMemoBuilder(
                paymentIntentId: id,
                accountKey: sender)
        }
    }
}

enum RTHMemoType {
    case unused
    case recoverable(sender: AccountKey)
    case recoverablePaymentRequest(sender: AccountKey, id: UInt64)
    case recoverablePaymentIntent(sender: AccountKey, id: UInt64)
}

class TxOutMemoBuilder {
    let ptr: OpaquePointer

    init(ptr: OpaquePointer) {
        self.ptr = ptr
    }

    deinit {
        mc_memo_builder_free(ptr)
    }

    static func createRecoverableMemoBuilder(accountKey: AccountKey) -> RecoverableMemoBuilder {
        RecoverableMemoBuilder(accountKey: accountKey)
    }

    static func createDefaultMemoBuilder() -> DefaultMemoBuilder {
        DefaultMemoBuilder()
    }

    static func createRecoverablePaymentRequestMemoBuilder(
        paymentRequestId: UInt64,
        accountKey: AccountKey
    ) -> RecoverablePaymentRequestMemoBuilder {
        RecoverablePaymentRequestMemoBuilder(
                paymentRequestId: paymentRequestId,
                accountKey: accountKey)
    }

    static func createRecoverablePaymentIntentMemoBuilder(
        paymentIntentId: UInt64,
        accountKey: AccountKey
    ) -> RecoverablePaymentIntentMemoBuilder {
        RecoverablePaymentIntentMemoBuilder(
                paymentIntentId: paymentIntentId,
                accountKey: accountKey)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }

    static func createMemoBuilder(type: RTHMemoType) -> TxOutMemoBuilder {
        switch type {
        case .unused:
            return createDefaultMemoBuilder()
        case .recoverable(let sender):
            return createRecoverableMemoBuilder(accountKey: sender)
        case let .recoverablePaymentRequest(sender, id):
            return createRecoverablePaymentRequestMemoBuilder(
                    paymentRequestId: id,
                    accountKey: sender)
        case let .recoverablePaymentIntent(sender, id):
            return createRecoverablePaymentIntentMemoBuilder(
                    paymentIntentId: id,
                    accountKey: sender)
        }
    }
}

final class RecoverableMemoBuilder: TxOutMemoBuilder {
    init(
        accountKey: AccountKey
    ) {
        // Safety: mc_memo_builder_sender_and_destination_create should never return nil.
        let pointer = withMcInfallible {
            accountKey.withUnsafeCStructPointer { acctKeyPtr in
                mc_memo_builder_sender_and_destination_create(acctKeyPtr)
            }
        }
        super.init(ptr: pointer)
    }
}

final class DefaultMemoBuilder: TxOutMemoBuilder {
    init() {
        // Safety: mc_memo_builder_default_create should never return nil.
        let pointer = withMcInfallible {
            mc_memo_builder_default_create()
        }
        super.init(ptr: pointer)
    }
}

final class RecoverablePaymentRequestMemoBuilder: TxOutMemoBuilder {
    init(
        paymentRequestId requestId: UInt64,
        accountKey: AccountKey
    ) {
        // Safety: mc_memo_builder_sender_and_destination_create should never return nil.
        let pointer = withMcInfallible {
            accountKey.withUnsafeCStructPointer { acctKeyPtr in
                mc_memo_builder_sender_payment_request_and_destination_create(requestId, acctKeyPtr)
            }
        }
        super.init(ptr: pointer)
    }
}

final class RecoverablePaymentIntentMemoBuilder: TxOutMemoBuilder {
    init(
        paymentIntentId intentId: UInt64,
        accountKey: AccountKey
    ) {
        // Safety: mc_memo_builder_sender_and_destination_create should never return nil.
        let pointer = withMcInfallible {
            accountKey.withUnsafeCStructPointer { acctKeyPtr in
                mc_memo_builder_sender_payment_intent_and_destination_create(intentId, acctKeyPtr)
            }
        }
        super.init(ptr: pointer)
    }
}
