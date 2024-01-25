//
//  Copyright (c) 2020-2022 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public struct SignedContingentInput {
    fileprivate let proto: External_SignedContingentInput

    public let requiredOutputAmounts: [Amount]
    public let pseudoOutputAmount: Amount
    public let changeAmount: Amount
    public let rewardAmount: Amount
    public let requiredAmount: Amount

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_SignedContingentInput(serializedData: serializedData) else {
            logger.warning("External_SignedContingentInput deserialization failed. " +
                "serializedData: \(redacting: serializedData.base64EncodedString())")
            return nil
        }

        guard let signedContingentInput = SignedContingentInput(proto) else {
            logger.warning("Input data is not a valid SignedContingentInput. serializedData: " +
                "\(redacting: serializedData.base64EncodedString())")
            return nil
        }

        self = signedContingentInput
    }

    public var serializedData: Data {
        proto.serializedDataInfallible
    }

    public var isValid: Bool {
        SignedContingentInputBuilderUtils.signed_contingent_input_is_valid(
            sciData: self.serializedData)
    }

    /// Block index at which this sci will no longer be considered valid for inclusion in
    /// the ledger by the consensus network.
    public var tombstoneBlockIndex: UInt64 {
        proto.txIn.inputRules.maxTombstoneBlock
    }

    public var feeTokenId: TokenId {
        rewardAmount.tokenId
    }

    enum AcceptedStatus {
        case notAccepted(knownToBeNotAcceptedTotalBlockCount: UInt64)
        case accepted(block: BlockMetadata)
        case tombstoneBlockExceeded
        case inputSpent

        var pending: Bool {
            switch self {
            case .notAccepted:
                return true
            case .accepted, .tombstoneBlockExceeded, .inputSpent:
                return false
            }
        }
    }
}

extension SignedContingentInput: Equatable {}
extension SignedContingentInput: Hashable {}

extension SignedContingentInput {
    init?(_ proto: External_SignedContingentInput) {
        self.proto = proto
        self.requiredOutputAmounts = proto.requiredOutputAmounts.map { Amount($0) }
        self.pseudoOutputAmount = Amount(proto.pseudoOutputAmount)

        // change amount:
        //  - find first required output amount with token id = pseudo amount token id and use
        //    that as the required change amount
        let changeTokenId = self.pseudoOutputAmount.tokenId
        self.changeAmount = requiredOutputAmounts.first(where: { $0.tokenId == changeTokenId }) ??
            Amount(0, in: changeTokenId )

        self.rewardAmount = Amount(pseudoOutputAmount.value - changeAmount.value, in: changeTokenId)

        self.requiredAmount = requiredOutputAmounts.first(where: { $0.tokenId != changeTokenId }) ??
        Amount(0, in: changeTokenId)
    }
}

extension External_SignedContingentInput {
    init(_ signedContingentInput: SignedContingentInput) {
        self = signedContingentInput.proto
    }
}

extension SignedContingentInput {

    internal func matchTxInWith(_ knownTxOuts: [KnownTxOut]) -> KnownTxOut? {
        guard proto.hasTxIn else {
            return nil
        }

        let ringPubKeySet = Set(proto.txIn.ring.map { RistrettoPublic($0.publicKey) })
        let matchingTxOuts = knownTxOuts.filter {
            ringPubKeySet.contains($0.publicKey) &&
            $0.tokenId == self.pseudoOutputAmount.tokenId &&
            $0.amount.value == UInt64(self.pseudoOutputAmount.value)
        }

        // there should be exactly one match
        guard matchingTxOuts.count == 1, let knownTxOut = matchingTxOuts.first else {
            return nil
        }

        return knownTxOut
    }
}
