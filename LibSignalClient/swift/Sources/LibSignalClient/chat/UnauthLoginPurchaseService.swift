//
// Copyright 2026 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public enum LoginReceiptLevel: Sendable {
    case normal
    case sandbox
}

public protocol UnauthLoginPurchaseService: Sendable {
    /// Obtain a ZK receipt credential for a completed one-time login payment.
    /// The receipt credential can then be presented at registration.
    ///
    /// Subsequent retries to create a login credential for the same `purchaseIdentifier` must use
    /// an identical `receiptCredentialRequestContext`.
    ///
    /// - Throws:
    ///   - ``SignalError/receiptCredentialErrorPaymentRequired(_:)`` if the purchase did not complete successfully.
    ///   - ``SignalError/receiptCredentialErrorPaymentStillProcessing(_:)``should be rare if payment has already
    ///   been confirmed locally, but the client may retry the request.
    ///   - ``SignalError/receiptCredentialErrorPaymentNotFound(_:)`` indicates that the server has no record of
    ///   `purchaseIdentifier`, which may be a client issue, a server issue, or a problem with the payment processor;
    ///   it is not worth retrying.
    ///   - ``SignalError/receiptCredentialErrorReceiptAlreadyIssued(_:)`` if the purchase was already redeemed for a receipt credential, but with a different receipt credential request.
    ///   - the standard Signal network errors
    func createLoginReceiptCredential(
        paymentProcessor: PaymentProvider,
        purchaseIdentifier: String,
        receiptCredentialRequestContext: ReceiptCredentialRequestContext,
        serverParams: ServerPublicParams,
        purchaseTime: Date,
        expectedLevel: LoginReceiptLevel,
    ) async throws -> ReceiptCredential
}

extension UnauthenticatedChatConnection: UnauthLoginPurchaseService {
    public func createLoginReceiptCredential(
        paymentProcessor: PaymentProvider,
        purchaseIdentifier: String,
        receiptCredentialRequestContext: ReceiptCredentialRequestContext,
        serverParams: ServerPublicParams,
        purchaseTime: Date,
        expectedLevel: LoginReceiptLevel,
    ) async throws -> ReceiptCredential {
        return try await NativeNice.UnauthenticatedChatConnection_create_login_receipt_credential(
            asyncContext: self.tokioAsyncContext,
            chat: self,
            paymentProcessor: paymentProcessor,
            purchaseIdentifier: purchaseIdentifier,
            receiptCredentialRequestContext: receiptCredentialRequestContext,
            serverParams: serverParams,
            purchaseTime: purchaseTime,
            expectedLevel: expectedLevel,
        )
    }

}

extension UnauthServiceSelector where Self == UnauthServiceSelectorHelper<any UnauthLoginPurchaseService> {
    public static var loginPurchase: Self { .init() }
}
