//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public struct Transaction {
    fileprivate let proto: External_Tx
    let inputKeyImagesTyped: Set<KeyImage>
    let outputs: Set<TxOut>

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_Tx(serializedData: serializedData) else {
            logger.warning("External_Tx deserialization failed. serializedData: " +
                "\(redacting: serializedData.base64EncodedString())")
            return nil
        }
        guard let transaction = Transaction(proto) else {
            logger.warning("Input data is not a valid Transaction. serializedData: " +
                "\(redacting: serializedData.base64EncodedString())")
            return nil
        }
        self = transaction
    }

    public var serializedData: Data {
        proto.serializedDataInfallible
    }

    var anyInputKeyImage: KeyImage {
        guard let inputKeyImage = inputKeyImagesTyped.first else {
            // Safety: Transaction is guaranteed to have at least 1 input.
            logger.fatalError("Transaction contains 0 inputs.")
        }
        return inputKeyImage
    }

    /// Key images of the `TxOut`'s being spent as the inputs to this `Transaction`.
    public var inputKeyImages: Set<Data> {
        Set(inputKeyImagesTyped.map { $0.data })
    }

    var anyOutput: TxOut {
        guard let output = outputs.first else {
            // Safety: Transaction is guaranteed to have at least 1 output.
            logger.fatalError("Transaction contains 0 outputs.")
        }
        return output
    }

    /// Public keys of the `TxOut`'s being created as the outputs from this `Transaction`.
    public var outputPublicKeys: Set<Data> {
        Set(outputs.map { $0.publicKey.data })
    }

    /// Fee paid to the MobileCoin Foundation for this transaction.
    public var fee: UInt64 {
        proto.prefix.fee
    }

    /// Block index at which this transaction will no longer be considered valid for inclusion in
    /// the ledger by the consensus network.
    public var tombstoneBlockIndex: UInt64 {
        proto.prefix.tombstoneBlock
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

extension Transaction: Equatable {}
extension Transaction: Hashable {}

extension Transaction {
    init?(_ proto: External_Tx) {
        guard proto.prefix.inputs.count > 0 && proto.prefix.outputs.count > 0 else {
            logger.warning("External_Tx doesn't contain at least 1 input and 1 output")
            return nil
        }
        guard proto.prefix.inputs.count == proto.signature.ringSignatures.count else {
            logger.warning("External_Tx input count is not equal to ring signature count")
            return nil
        }
        self.proto = proto

        var keyImages: [KeyImage] = []
        for ringSignature in proto.signature.ringSignatures {
            guard let keyImage = KeyImage(ringSignature.keyImage) else {
                logger.warning("External_Tx contains an invalid KeyImage")
                return nil
            }
            keyImages.append(keyImage)
        }
        self.inputKeyImagesTyped = Set(keyImages)

        var outputs: [TxOut] = []
        for output in proto.prefix.outputs {
            switch TxOut.make(output) {
            case .success(let txOut):
                outputs.append(txOut)
            case .failure(let error):
                logger.warning("External_Tx contains an invalid output. error: \(error)")
                return nil
            }
        }
        self.outputs = Set(outputs)
    }
}

extension External_Tx {
    init(_ transaction: Transaction) {
        self = transaction.proto
    }
}
