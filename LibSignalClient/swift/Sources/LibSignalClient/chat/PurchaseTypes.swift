//
// Copyright 2026 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

public enum PaymentProvider: Sendable, Equatable {
    case googlePlayBilling
    case appleAppStore
    case stripe
    case braintree
}

/// Information about a charge failure.
///
/// Meaningfully interpreting chargeFailure response fields requires inspecting the processor field
/// first.
///
/// For Stripe, code will be one of the [codes defined here](https://stripe.com/docs/api/charges/object#charge_object-failure_code),
/// while message [may contain a further textual description](https://stripe.com/docs/api/charges/object#charge_object-failure_message).
/// The outcome fields are optional, but present values will directly map to Stripe
/// [response properties](https://stripe.com/docs/api/charges/object#charge_object-outcome-network_status)
///
/// For Braintree, the outcome fields will be null. The code and message will contain one of
///   - a processor decline code (as a string) in code, and associated text in message, as defined
///     this [table](https://developer.paypal.com/braintree/docs/reference/general/processor-responses/authorization-responses)
///   - `gateway` in code, with a [reason](https://developer.paypal.com/braintree/articles/control-panel/transactions/gateway-rejections) in message
///   - `code` = "unknown", message = "unknown"
///
/// IAP payment processors will never include charge failure information, and detailed order
/// information should be retrieved from the payment processor directly.
public struct ChargeFailure: Sendable, Equatable {
    public var processor: PaymentProvider
    /// See [Stripe failure codes](https://stripe.com/docs/api/charges/object#charge_object-failure_code)
    /// or [Braintree decline codes](https://developer.paypal.com/braintree/docs/reference/general/processor-responses/authorization-responses#decline-codes)
    /// depending on which processor was used
    public var code: String
    /// See [Stripe failure codes](https://stripe.com/docs/api/charges/object#charge_object-failure_code)
    /// or [Braintree decline codes](https://developer.paypal.com/braintree/docs/reference/general/processor-responses/authorization-responses#decline-codes)
    /// depending on which processor was used
    public var message: String
    /// See [Outcome Network Status](https://stripe.com/docs/api/charges/object#charge_object-outcome-network_status)
    public var outcomeNetworkStatus: String?
    /// See [Outcome Reason](https://stripe.com/docs/api/charges/object#charge_object-outcome-reason)
    public var outcomeReason: String?
    /// See [Outcome Type](https://stripe.com/docs/api/charges/object#charge_object-outcome-type)
    public var outcomeType: String?

    public init(
        processor: PaymentProvider,
        code: String,
        message: String,
        outcomeNetworkStatus: String? = nil,
        outcomeReason: String? = nil,
        outcomeType: String? = nil
    ) {
        self.processor = processor
        self.code = code
        self.message = message
        self.outcomeNetworkStatus = outcomeNetworkStatus
        self.outcomeReason = outcomeReason
        self.outcomeType = outcomeType
    }
}
