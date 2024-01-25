//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

/// Represents a single "output" `TxOut` from a `Transaction`. Intended to be serialized and sent to
/// the recipient of that `TxOut`. The recipient is able to use `Receipt` to validate that a
/// particular `TxOut` was sent by whoever sent them the `Receipt`, assuming the public key of the
/// `Receipt` and the `TxOut` in question are the same and various other validation checks pass. The
/// `Receipt` also contains the necessary information to determine whether an expected, incoming
/// `TxOut`'s `Tx` has expired, in which case, if the `TxOut` is not in the ledger at that point,
/// then the corresponding `Tx` is no longer eligible to be accepted into consensus.
///
/// # Security
/// The `Receipt` contains the `TxOutConfirmationNumber`, which is used by the recipient as evidence
/// that a particular party is the one who sent the corresponding `TxOut` that the `Receipt`
/// represents. Therefore, care should be taken to ensure that only the sender and the recipient
/// have access to the `Receipt`, otherwise the recipient could be tricked into misattributing which
/// party sent them a particular `TxOut`.
public struct Receipt {
    let txOutPublicKeyTyped: RistrettoPublic
    let maskedAmount: MaskedAmount
    let confirmationNumber: TxOutConfirmationNumber

    /// Block index at which the transaction that produced this `Receipt` will no longer be
    /// considered valid for inclusion in the ledger by the consensus network.
    public let txTombstoneBlockIndex: UInt64

    init(
        txOut: TxOut,
        confirmationNumber: TxOutConfirmationNumber,
        tombstoneBlockIndex: UInt64
    ) {
        self.txOutPublicKeyTyped = txOut.publicKey
        self.maskedAmount = txOut.maskedAmount
        self.confirmationNumber = confirmationNumber
        self.txTombstoneBlockIndex = tombstoneBlockIndex
    }

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_Receipt(serializedData: serializedData) else {
            logger.warning(
                "External_Receipt deserialization failed. serializedData: " +
                    "\(redacting: serializedData.base64EncodedString())",
                logFunction: false)
            return nil
        }
        self.init(proto)
    }

    var commitment: Data32 { maskedAmount.commitment }

    public var serializedData: Data {
        let proto = External_Receipt(self)
        return proto.serializedDataInfallible
    }

    /// Public key of the `TxOut` that this `Receipt` represents, in bytes.
    public var txOutPublicKey: Data {
        txOutPublicKeyTyped.data
    }

    // swiftlint:disable todo
    func matchesTxOut(_ txOut: TxOutProtocol) -> Bool {
        txOutPublicKeyTyped == txOut.publicKey
            && commitment == txOut.commitment
            // TODO - verify with core-eng that commitment is sufficient, 
            // remove after confirmation
    }
    // swiftlint:enable todo

    func validateConfirmationNumber(accountKey: AccountKey) -> Bool {
        TxOutUtils.validateConfirmationNumber(
            publicKey: txOutPublicKeyTyped,
            confirmationNumber: confirmationNumber,
            viewPrivateKey: accountKey.viewPrivateKey)
    }

    func unmaskValue(accountKey: AccountKey) -> Result<UInt64, InvalidInputError> {
        unmaskAmount(accountKey: accountKey).map {
            $0.value
        }
    }

    func unmaskAmount(accountKey: AccountKey) -> Result<Amount, InvalidInputError> {
        guard let amount = TxOutUtils.amount(
            maskedAmount: maskedAmount,
            publicKey: txOutPublicKeyTyped,
            viewPrivateKey: accountKey.viewPrivateKey)
        else {
            logger.info("")
            return .failure(InvalidInputError("accountKey does not own Receipt"))
        }
        return .success(amount)
    }

    /// Validates whether or not `Receipt` is well-formed and matches `accountKey`, returning `nil`
    /// if either of these conditions are not met. Otherwise, returns the value of the `TxOut`
    /// represented by this `Receipt`.
    ///
    /// Note: Receipt does not provide enough information to distinguish between subaddresses of an
    /// `accountKey`, so this function only validates that the `Receipt` was addressed to a
    /// subaddress of the `accountKey`, but not which one.
    @discardableResult
    public func validateAndUnmaskValue(accountKey: AccountKey) -> UInt64? {
        validateAndUnmaskAmount(accountKey: accountKey)?.value
    }

    /// Validates whether or not `Receipt` is well-formed and matches `accountKey`, returning `nil`
    /// if either of these conditions are not met. Otherwise, returns the `Amount` of the `TxOut`
    /// represented by this `Receipt`. `Amount` is a value and a tokenId
    ///
    /// Note: Receipt does not provide enough information to distinguish between subaddresses of an
    /// `accountKey`, so this function only validates that the `Receipt` was addressed to a
    /// subaddress of the `accountKey`, but not which one.
    @discardableResult
    public func validateAndUnmaskAmount(accountKey: AccountKey) -> Amount? {
        guard validateConfirmationNumber(accountKey: accountKey) else {
            return nil
        }

        guard let amount = TxOutUtils.amount(
                maskedAmount: maskedAmount,
                publicKey: txOutPublicKeyTyped,
                viewPrivateKey: accountKey.viewPrivateKey)
        else {
            return nil
        }

        return amount
    }

    enum ReceivedStatus {
        case notReceived(knownToBeNotReceivedBlockCount: UInt64?)
        case received(block: BlockMetadata)
        case tombstoneExceeded

        var pending: Bool {
            switch self {
            case .notReceived:
                return true
            case .received, .tombstoneExceeded:
                return false
            }
        }
    }
}

extension Receipt: Equatable {}
extension Receipt: Hashable {}

extension Receipt {
    init?(_ proto: External_Receipt) {

        guard let txOutPublicKey = RistrettoPublic(proto.publicKey.data),
              let maskedAmountProto = proto.maskedAmount,
              let maskedAmount = MaskedAmount(maskedAmountProto),
              let confirmationNumber = TxOutConfirmationNumber(proto.confirmation)
        else {
            logger.warning(
                "Failed to initialize Receipt with External_Receipt. serialized proto: " +
                    "\(redacting: proto.serializedDataInfallible.base64EncodedString())",
                logFunction: false)
            return nil
        }

        self.txOutPublicKeyTyped = txOutPublicKey
        self.maskedAmount = maskedAmount
        self.confirmationNumber = confirmationNumber
        self.txTombstoneBlockIndex = proto.tombstoneBlock
    }
}

extension External_Receipt {
    init(_ receipt: Receipt) {
        self.init()
        self.publicKey = External_CompressedRistretto(receipt.txOutPublicKey)
        self.confirmation = External_TxOutConfirmationNumber(receipt.confirmationNumber)
        self.tombstoneBlock = receipt.txTombstoneBlockIndex

        switch receipt.maskedAmount.version {
        case .v1:
            self.maskedAmountV1.commitment = External_CompressedRistretto(receipt.commitment)
            self.maskedAmountV1.maskedValue = receipt.maskedAmount.maskedValue
            self.maskedAmountV1.maskedTokenID = receipt.maskedAmount.maskedTokenId
        case .v2:
            self.maskedAmountV2.commitment = External_CompressedRistretto(receipt.commitment)
            self.maskedAmountV2.maskedValue = receipt.maskedAmount.maskedValue
            self.maskedAmountV2.maskedTokenID = receipt.maskedAmount.maskedTokenId
        }
    }
}
