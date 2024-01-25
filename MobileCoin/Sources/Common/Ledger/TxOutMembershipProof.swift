//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct TxOutMembershipProof {
    let serializedData: Data

    static func make(serializedData: Data) -> Result<TxOutMembershipProof, InvalidInputError> {
        .success(TxOutMembershipProof(serializedData: serializedData))
    }

    private init(serializedData: Data) {
        self.serializedData = serializedData
    }
}

extension TxOutMembershipProof: Equatable {}
extension TxOutMembershipProof: Hashable {}

extension TxOutMembershipProof {
    static func make(_ txOutMembershipProof: External_TxOutMembershipProof)
        -> Result<TxOutMembershipProof, InvalidInputError>
    {
        let serializedData = txOutMembershipProof.serializedDataInfallible
        return TxOutMembershipProof.make(serializedData: serializedData)
    }
}
