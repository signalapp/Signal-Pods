//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

public struct Transaction {
    fileprivate let proto: External_Tx
    let inputKeyImagesTyped: Set<KeyImage>
    let outputs: Set<TxOut>

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        logger.debug("serializedData: \(redacting: serializedData)")
        guard let proto = try? External_Tx(serializedData: serializedData) else {
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        do {
            return try proto.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError("Protobuf serialization failed: \(redacting: error)")
        }
    }

    var anyInputKeyImage: KeyImage {
        guard let inputKeyImage = inputKeyImagesTyped.first else {
            // Safety: Transaction is guaranteed to have at least 1 input.
            logger.fatalError("Error: Transaction contains 0 inputs.")
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
            logger.fatalError("Error: Transaction contains 0 outputs.")
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
        logger.info("")
        guard proto.prefix.inputs.count > 0 && proto.prefix.outputs.count > 0 else {
            return nil
        }
        self.proto = proto
        self.inputKeyImagesTyped = Set(proto.signature.ringSignatures.map {
            guard let keyImage = KeyImage($0.keyImage) else {
                logger.fatalError("serialization failure")
            }
            return keyImage
        })
        self.outputs = Set(proto.prefix.outputs.map {
            let txOutData: Data
            do {
                txOutData = try $0.serializedData()
            } catch {
                // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
                logger.fatalError("Protobuf serialization failed: \(redacting: error)")
            }
            guard let txOut = TxOut(serializedData: txOutData) else {
                logger.fatalError("serialization failure")
            }
            return txOut
        })
    }
}

extension External_Tx {
    init(_ transaction: Transaction) {
        self = transaction.proto
    }
}
