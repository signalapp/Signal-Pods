//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

final class Account {
    let accountKey: AccountKey

    let fogView = FogView()

    var allTxOutTrackers: [TxOutTracker] = []
    var unscannedMissedBlocksRanges: [Range<UInt64>] = []

    init(accountKey: AccountKeyWithFog) {
        self.accountKey = accountKey.accountKey
    }

    var publicAddress: PublicAddress {
        accountKey.publicAddress
    }

    private var allTxOutsFoundBlockCount: UInt64 {
        var allTxOutsFoundBlockCount = fogView.allRngTxOutsFoundBlockCount
        for unscannedMissedBlocksRange in unscannedMissedBlocksRanges
            where unscannedMissedBlocksRange.lowerBound < allTxOutsFoundBlockCount
        {
            allTxOutsFoundBlockCount = unscannedMissedBlocksRange.lowerBound
        }
        return allTxOutsFoundBlockCount
    }

    /// The number of blocks for which we have complete knowledge of this Account's wallet.
    private var knowableBlockCount: UInt64 {
        var knowableBlockCount = allTxOutsFoundBlockCount
        for txOut in allTxOutTrackers {
            if case .unspent(let knownToBeUnspentBlockCount) = txOut.spentStatus {
                knowableBlockCount = min(knowableBlockCount, knownToBeUnspentBlockCount)
            }
        }
        return knowableBlockCount
    }

    var cachedBalance: Balance {
        cachedBalance(atBlockCount: knowableBlockCount)
    }

    func cachedBalance(atBlockCount blockCount: UInt64) -> Balance {
        let txOutValues = allTxOutTrackers.map { $0.netValue(atBlockCount: blockCount) }
        return Balance(values: txOutValues, blockCount: blockCount)
    }

    var cachedAccountActivity: AccountActivity {
        let blockCount = knowableBlockCount
        let txOuts = allTxOutTrackers.compactMap { OwnedTxOut($0, atBlockCount: blockCount) }
        return AccountActivity(txOuts: txOuts, blockCount: blockCount)
    }

    var allTxOuts: [KnownTxOut] {
        allTxOutTrackers.map { $0.knownTxOut }
    }

    var unspentTxOuts: [KnownTxOut] {
        allTxOutTrackers.filter { !$0.isSpent }.map { $0.knownTxOut }
    }

    func addTxOuts(_ txOuts: [KnownTxOut]) {
        allTxOutTrackers.append(contentsOf: txOuts.map { TxOutTracker($0) })
    }

    func cachedReceivedStatus(of receipt: Receipt) throws -> Receipt.ReceivedStatus {
        guard let ownedTxOut = try ownedTxOut(for: receipt) else {
            let knownToBeNotReceivedBlockCount = allTxOutsFoundBlockCount
            guard receipt.txTombstoneBlockIndex > knownToBeNotReceivedBlockCount else {
                return .tombstoneExceeded
            }
            return .notReceived(knownToBeNotReceivedBlockCount: knownToBeNotReceivedBlockCount)
        }

        return .received(block: ownedTxOut.block)
    }

    func cachedSpentStatus(of keyImage: KeyImage) -> KeyImage.SpentStatus? {
        allTxOutTrackers.map { $0.keyImageTracker }.first { $0.keyImage == keyImage }?.spentStatus
    }

    /// Retrieves the `KnownTxOut`'s corresponding to `receipt` and verifies `receipt` is valid.
    private func ownedTxOut(for receipt: Receipt) throws -> KnownTxOut? {
        print("Checking received status of TxOut: Tx pubkey: " +
            "\(receipt.txOutPublicKey.base64EncodedString())")
        if let lastTxOut = allTxOuts.last {
            print("Last received TxOut: Tx pubkey: " +
                "\(lastTxOut.publicKey.base64EncodedString())")
        }

        // First check if we've received the TxOut (either from Fog View or from view key scanning).
        // This has the benefit of providing a guarantee that the TxOut is owned by this account.
        guard let ownedTxOut = ownedTxOut(withPublicKey: receipt.txOutPublicKeyTyped) else {
            return nil
        }

        // Make sure the Receipt data matches the TxOut found in the ledger. This verifies that the
        // public key, commitment, and masked value match.
        //
        // Note: This doesn't verify the confirmation number or tombstone block (since neither are
        // saved to the ledger).
        guard receipt.matchesTxOut(ownedTxOut) else {
            throw InvalidReceipt("Receipt data doesn't match the corresponding TxOut found in " +
                "the ledger.")
        }

        // Verify that the confirmation number validates for this account key. This provides a
        // guarantee that the sender of the Receipt was the creator of the TxOut that we received.
        guard receipt.validateConfirmationNumber(accountKey: accountKey) else {
            throw InvalidReceipt("Receipt confirmation number is invalid.")
        }

        return ownedTxOut
    }

    private func ownedTxOut(withPublicKey publicKey: RistrettoPublic) -> KnownTxOut? {
        allTxOuts.first(where: { $0.publicKey == publicKey })
    }
}

extension Account {
    convenience init(accountKey: AccountKey) throws {
        guard let accountKey = AccountKeyWithFog(accountKey: accountKey) else {
            throw MalformedInput("Accounts without fog URLs are not currently supported.")
        }

        self.init(accountKey: accountKey)
    }
}

final class TxOutTracker {
    let knownTxOut: KnownTxOut

    var keyImageTracker: KeyImageSpentTracker

    init(_ knownTxOut: KnownTxOut) {
        self.knownTxOut = knownTxOut
        self.keyImageTracker = KeyImageSpentTracker(knownTxOut.keyImage)
    }

    var spentStatus: KeyImage.SpentStatus {
        keyImageTracker.spentStatus
    }

    func netValue(atBlockCount blockCount: UInt64) -> UInt64 {
        guard knownTxOut.block.index < blockCount else {
            return 0
        }
        if case .spent(block: let spentAtBlock) = keyImageTracker.spentStatus {
            guard spentAtBlock.index >= blockCount else {
                return 0
            }
        }
        return knownTxOut.value
    }

    var isSpent: Bool {
        keyImageTracker.isSpent
    }
}

extension OwnedTxOut {
    fileprivate init?(_ txOutTracker: TxOutTracker, atBlockCount blockCount: UInt64) {
        guard txOutTracker.knownTxOut.block.index < blockCount else {
            return nil
        }
        let receivedBlock = txOutTracker.knownTxOut.block

        let spentBlock: BlockMetadata?
        if case .spent(let block) = txOutTracker.spentStatus, block.index < blockCount {
            spentBlock = block
        } else {
            spentBlock = nil
        }

        self.init(txOutTracker.knownTxOut, receivedBlock: receivedBlock, spentBlock: spentBlock)
    }
}
