//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct TxOutMembershipProof {
    let serializedData: Data

    /// - Returns: `nil` when the input is not deserializable.
    init?(serializedData: Data) {
        logger.info("")
        self.serializedData = serializedData
    }
}

extension TxOutMembershipProof: Equatable {}
extension TxOutMembershipProof: Hashable {}

extension TxOutMembershipProof {
    init?(_ txOutMembershipProof: External_TxOutMembershipProof) {
        logger.info("")
        let serializedData: Data
        do {
            serializedData = try txOutMembershipProof.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError("Protobuf serialization failed: \(redacting: error)")
        }
        self.init(serializedData: serializedData)
    }
}
