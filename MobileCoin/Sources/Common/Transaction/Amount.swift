//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public struct Amount {
    public let value: UInt64
    public let tokenId: TokenId
}

extension Amount {
    public init(_ value: UInt64, in tokenId: TokenId) {
        self.value = value
        self.tokenId = tokenId
    }

    init(mob: UInt64) {
        self.init(value: mob, tokenId: .MOB)
    }
}

extension Amount: CustomStringConvertible {
    public var description: String {
        "\(value) \(tokenId.description)"
    }
}

extension Amount: Equatable, Hashable {}

extension Amount {
    init(_ amount: McTxOutAmount) {
        self.value = amount.value
        self.tokenId = TokenId(amount.token_id)
    }
}

extension Amount {
    init(_ amount: External_UnmaskedAmount) {
        self.value = amount.value
        self.tokenId = TokenId(amount.tokenID)
    }
}
