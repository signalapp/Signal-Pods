//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

public struct TransferPayload {
    let rootEntropy32: Data32
    let txOutPublicKey: RistrettoPublic
    public let memo: String?

    init(rootEntropy: Data32, txOutPublicKey: RistrettoPublic, memo: String? = nil) {
        logger.info("")
        self.rootEntropy32 = rootEntropy
        self.txOutPublicKey = txOutPublicKey
        self.memo = memo?.isEmpty == false ? memo : nil
    }

    public var rootEntropy: Data {
        rootEntropy32.data
    }
}

extension TransferPayload: Equatable {}
extension TransferPayload: Hashable {}

extension TransferPayload {
    init?(_ transferPayload: Printable_TransferPayload) {
        logger.info("")
        guard let rootEntropy = Data32(transferPayload.entropy),
              let txOutPublicKey = RistrettoPublic(transferPayload.txOutPublicKey.data)
        else {
            return nil
        }
        self.rootEntropy32 = rootEntropy
        self.txOutPublicKey = txOutPublicKey
        self.memo = !transferPayload.memo.isEmpty ? transferPayload.memo : nil
    }
}

extension Printable_TransferPayload {
    init(_ transferPayload: TransferPayload) {
        logger.info("")
        self.init()
        self.entropy = transferPayload.rootEntropy
        self.txOutPublicKey = External_CompressedRistretto(transferPayload.txOutPublicKey)
        if let memo = transferPayload.memo {
            self.memo = memo
        }
    }
}
