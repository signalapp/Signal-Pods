//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

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
    let commitment: Data32
    let maskedValue: UInt64
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
        self.commitment = txOut.commitment
        self.maskedValue = txOut.maskedValue
        self.confirmationNumber = confirmationNumber
        self.txTombstoneBlockIndex = tombstoneBlockIndex
    }

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_Receipt(serializedData: serializedData) else {
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        let proto = External_Receipt(self)
        do {
            return try proto.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            logger.fatalError(
                "Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }
    }

    /// Public key of the `TxOut` that this `Receipt` represents, in bytes.
    public var txOutPublicKey: Data {
        txOutPublicKeyTyped.data
    }

    func matchesTxOut(_ txOut: TxOutProtocol) -> Bool {
        txOutPublicKeyTyped == txOut.publicKey
            && commitment == txOut.commitment
            && maskedValue == txOut.maskedValue
    }

    func validateConfirmationNumber(accountKey: AccountKey) -> Bool {
        TxOutUtils.validateConfirmationNumber(
            publicKey: txOutPublicKeyTyped,
            confirmationNumber: confirmationNumber,
            viewPrivateKey: accountKey.viewPrivateKey)
    }

    func unmaskValue(accountKey: AccountKey) -> Result<UInt64, InvalidInputError> {
        guard let value = TxOutUtils.value(
            commitment: commitment,
            maskedValue: maskedValue,
            publicKey: txOutPublicKeyTyped,
            viewPrivateKey: accountKey.viewPrivateKey)
        else {
            return .failure(InvalidInputError("accountKey does not own Receipt"))
        }
        return .success(value)
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
        guard validateConfirmationNumber(accountKey: accountKey) else {
            return nil
        }

        guard let value = TxOutUtils.value(
                commitment: commitment,
                maskedValue: maskedValue,
                publicKey: txOutPublicKeyTyped,
                viewPrivateKey: accountKey.viewPrivateKey)
        else {
            return nil
        }

        return value
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
              let commitment = Data32(proto.amount.commitment.data),
              let confirmationNumber = TxOutConfirmationNumber(proto.confirmation)
        else {
            return nil
        }
        self.txOutPublicKeyTyped = txOutPublicKey
        self.commitment = commitment
        self.maskedValue = proto.amount.maskedValue
        self.confirmationNumber = confirmationNumber
        self.txTombstoneBlockIndex = proto.tombstoneBlock
    }
}

extension External_Receipt {
    init(_ receipt: Receipt) {
        self.init()
        self.publicKey = External_CompressedRistretto(receipt.txOutPublicKey)
        self.amount.commitment = External_CompressedRistretto(receipt.commitment)
        self.amount.maskedValue = receipt.maskedValue
        self.confirmation = External_TxOutConfirmationNumber(receipt.confirmationNumber)
        self.tombstoneBlock = receipt.txTombstoneBlockIndex
    }
}
