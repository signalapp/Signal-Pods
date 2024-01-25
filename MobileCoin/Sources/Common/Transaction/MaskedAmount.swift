//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct MaskedAmount {
    enum Version {
        case v1
        case v2
    }

    let maskedValue: UInt64
    let maskedTokenId: Data
    let commitment: Data32
    let version: Version

    var libmobilecoin_version: McMaskedAmountVersion {
        version.libmobilecoin_version
    }
}

extension MaskedAmount.Version {
    var libmobilecoin_version: McMaskedAmountVersion {
        switch self {
        case .v1:
            return V1
        case .v2:
            return V2
        }
    }
}

extension MaskedAmount {
    init?(_ proto: External_TxOut.OneOf_MaskedAmount) {
        switch proto {
        case .maskedAmountV1(let maskedAmount):
            self.commitment = Data32(maskedAmount.commitment.data) ?? Data32()
            self.maskedValue = maskedAmount.maskedValue
            self.maskedTokenId = maskedAmount.maskedTokenID
            self.version = Version.v1
        case .maskedAmountV2(let maskedAmount):
            self.commitment = Data32(maskedAmount.commitment.data) ?? Data32()
            self.maskedValue = maskedAmount.maskedValue
            self.maskedTokenId = maskedAmount.maskedTokenID
            self.version = Version.v2
        }
    }
}

extension MaskedAmount {
    init?(_ proto: FogView_TxOutRecord) {
        switch proto.txOutAmountMaskedTokenID {
        case .txOutAmountMaskedV1TokenID(let maskedTokenID):
            self.commitment = Data32(proto.txOutAmountCommitmentData) ?? Data32()
            self.maskedValue = proto.txOutAmountMaskedValue
            self.maskedTokenId = maskedTokenID
            self.version = Version.v1
        case .txOutAmountMaskedV2TokenID(let maskedTokenID):
            self.commitment = Data32(proto.txOutAmountCommitmentData) ?? Data32()
            self.maskedValue = proto.txOutAmountMaskedValue
            self.maskedTokenId = maskedTokenID
            self.version = Version.v2
        case .none:
            // Same as "empty"/"missing" which means its token_id 0 for MOB
            self.commitment = Data32(proto.txOutAmountCommitmentData) ?? Data32()
            self.maskedValue = proto.txOutAmountMaskedValue
            self.maskedTokenId = Data()
            self.version = Version.v1
        }
    }
}

extension MaskedAmount {
    init?(_ proto: External_Receipt.OneOf_MaskedAmount) {
        switch proto {
        case .maskedAmountV1(let maskedAmount):
            self.commitment = Data32(maskedAmount.commitment.data) ?? Data32()
            self.maskedValue = maskedAmount.maskedValue
            self.maskedTokenId = maskedAmount.maskedTokenID
            self.version = Version.v1
        case .maskedAmountV2(let maskedAmount):
            self.commitment = Data32(maskedAmount.commitment.data) ?? Data32()
            self.maskedValue = maskedAmount.maskedValue
            self.maskedTokenId = maskedAmount.maskedTokenID
            self.version = Version.v2
        }
    }
}

extension MaskedAmount.Version: CustomStringConvertible {
    public var description: String {
        switch self {
        case .v1:
            return "Version 1"
        case .v2:
            return "Version 2"
        }
    }
}
extension MaskedAmount: Hashable, Equatable, CustomStringConvertible {
    public var description: String {
        "maskedValue \(maskedValue) \n" +
        "maskedTokenId \(maskedTokenId.hexEncodedString()) \n" +
        "version \(version) \n"
    }
}
