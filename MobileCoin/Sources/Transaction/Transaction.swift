//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable todo

import Foundation
import LibMobileCoin

enum TransactionBuilderError: Error {
    // TODO: Enumerate errors
}

public struct Transaction {
    fileprivate let proto: External_Tx

    /// - Returns: `nil` when the input is not deserializable.
    public init?(serializedData: Data) {
        guard let proto = try? External_Tx(serializedData: serializedData) else {
            return nil
        }
        self.init(proto)
    }

    public var serializedData: Data {
        do {
            return try proto.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            fatalError("Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }
    }

    var inputKeyImagesTyped: Set<KeyImage> {
        Set(proto.signature.ringSignatures.map {
            guard let keyImage = KeyImage($0.keyImage) else {
                fatalError("\(Self.self).\(#function): serialization failure")
            }
            return keyImage
        })
    }

    /// Key images of the `TxOut`'s being spent as the inputs to this `Transaction`.
    public var inputKeyImages: Set<Data> {
        Set(inputKeyImagesTyped.map { $0.data })
    }

    var outputs: Set<TxOut> {
        Set(proto.prefix.outputs.map {
            let txOutData: Data
            do {
                txOutData = try $0.serializedData()
            } catch {
                // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
                fatalError(
                    "Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
            }
            guard let txOut = TxOut(serializedData: txOutData) else {
                fatalError("\(Self.self).\(#function): serialization failure")
            }
            return txOut
        })
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
        self.proto = proto
    }
}

extension External_Tx {
    init(_ transaction: Transaction) {
        self = transaction.proto
    }
}
