//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

public struct TransferPayload {
    let rootEntropy32: Data32?
    let bip39_32: Data32?
    let txOutPublicKey: RistrettoPublic
    public let memo: String?

    init(rootEntropy: Data32, txOutPublicKey: RistrettoPublic, memo: String? = nil) {
        self.rootEntropy32 = rootEntropy
        self.bip39_32 = nil
        self.txOutPublicKey = txOutPublicKey
        self.memo = memo?.isEmpty == false ? memo : nil
    }

    init(bip39: Data32, txOutPublicKey: RistrettoPublic, memo: String? = nil) {
        self.bip39_32 = bip39
        self.rootEntropy32 = nil
        self.txOutPublicKey = txOutPublicKey
        self.memo = memo?.isEmpty == false ? memo : nil
    }

    public var rootEntropy: Data? {
        rootEntropy32?.data
    }

    public var bip39: Data? {
        bip39_32?.data
    }
}

extension TransferPayload: Equatable {}
extension TransferPayload: Hashable {}

extension TransferPayload {
    init?(_ transferPayload: Printable_TransferPayload) {
        guard let txOutPublicKey = RistrettoPublic(transferPayload.txOutPublicKey.data) else {
            return nil
        }

        // this is to verify against setting both rootEntropy and bip39 to
        // to non-empty data (can fall through later checks if exactly one is valid Data32)
        let hasRootEntropy = !transferPayload.rootEntropy.isEmpty
        let hasBip39 = !transferPayload.bip39Entropy.isEmpty
        guard !(hasRootEntropy && hasBip39) else {
            return nil
        }

        // convert to Data32 in order to be able to verify the raw Data is valid
        let rootEntropy = Data32(transferPayload.rootEntropy)
        let bip39 = Data32(transferPayload.bip39Entropy)

        // must have exactly one of bip39 or rootEntropy
        switch (bip39, rootEntropy) {
        case (.some(let bip39), nil):
            self.init(bip39: bip39, txOutPublicKey: txOutPublicKey, memo: transferPayload.memo)
        case (nil, .some(let rootEntropy)):
            self.init(
                rootEntropy: rootEntropy,
                txOutPublicKey: txOutPublicKey,
                memo: transferPayload.memo)
        default:
            return nil
        }
    }
}

extension Printable_TransferPayload {
    init(_ transferPayload: TransferPayload) {
        self.init()
        self.rootEntropy = transferPayload.rootEntropy ?? self.rootEntropy
        self.bip39Entropy = transferPayload.bip39 ?? self.bip39Entropy
        self.txOutPublicKey = External_CompressedRistretto(transferPayload.txOutPublicKey)
        if let memo = transferPayload.memo {
            self.memo = memo
        }
    }
}
