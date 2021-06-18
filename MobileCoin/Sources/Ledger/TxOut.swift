//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct TxOut: TxOutProtocol {
    fileprivate let proto: External_TxOut

    let commitment: Data32
    let targetKey: RistrettoPublic
    let publicKey: RistrettoPublic

    /// - Returns: `nil` when the input is not deserializable.
    init?(serializedData: Data) {
        guard let proto = try? External_TxOut(serializedData: serializedData) else {
            logger.warning(
                "External_TxOut deserialization failed. serializedData: " +
                    "\(redacting: serializedData.base64EncodedString())",
                logFunction: false)
            return nil
        }

        switch TxOut.make(proto) {
        case .success(let txOut):
            self = txOut
        case .failure(let error):
            logger.warning(
                "External_TxOut deserialization failed. serializedData: " +
                    "\(redacting: serializedData.base64EncodedString()), error: \(error)",
                logFunction: false)
            return nil
        }
    }

    var serializedData: Data {
        proto.serializedDataInfallible
    }

    var maskedValue: UInt64 { proto.amount.maskedValue }
    var encryptedFogHint: Data { proto.eFogHint.data }
}

extension TxOut: Equatable {}
extension TxOut: Hashable {}

extension TxOut {
    static func make(_ proto: External_TxOut) -> Result<TxOut, InvalidInputError> {
        guard let commitment = Data32(proto.amount.commitment.data) else {
            return .failure(
                InvalidInputError("Failed parsing External_TxOut: invalid commitment format"))
        }
        guard let targetKey = RistrettoPublic(proto.targetKey.data) else {
            return .failure(
                InvalidInputError("Failed parsing External_TxOut: invalid target key format"))
        }
        guard let publicKey = RistrettoPublic(proto.publicKey.data) else {
            return .failure(
                InvalidInputError("Failed parsing External_TxOut: invalid public key format"))
        }
        return .success(
            TxOut(proto: proto, commitment: commitment, targetKey: targetKey, publicKey: publicKey))
    }

    private init(
        proto: External_TxOut,
        commitment: Data32,
        targetKey: RistrettoPublic,
        publicKey: RistrettoPublic
    ) {
        self.proto = proto
        self.commitment = commitment
        self.targetKey = targetKey
        self.publicKey = publicKey
    }
}

extension External_TxOut {
    init(_ txOut: TxOut) {
        self = txOut.proto
    }
}
