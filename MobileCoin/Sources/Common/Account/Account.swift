//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class Account {
    let accountKey: AccountKey

    let fogView: FogView

    let syncCheckerLock: ReadWriteDispatchLock<FogSyncCheckable>

    var allTxOutTrackers: [TxOutTracker] = []

    init(accountKey: AccountKeyWithFog, syncChecker: FogSyncCheckable) {
        self.accountKey = accountKey.accountKey
        self.syncCheckerLock = .init(syncChecker)
        self.fogView = FogView(syncChecker: syncCheckerLock)
    }

    var publicAddress: PublicAddress {
        accountKey.publicAddress
    }

    var unscannedMissedBlocksRanges: [Range<UInt64>] { fogView.unscannedMissedBlocksRanges }

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
    var knowableBlockCount: UInt64 {
        var knowableBlockCount = allTxOutsFoundBlockCount
        for txOut in allTxOutTrackers {
            if case .unspent(let knownToBeUnspentBlockCount) = txOut.spentStatus {
                knowableBlockCount = min(knowableBlockCount, knownToBeUnspentBlockCount)
            }
        }
        return knowableBlockCount
    }

    @available(*, deprecated, message: "Use cachedBalance(for:TokenId)")
    var cachedBalance: Balance {
        cachedBalance(for: .MOB)
    }

    var cachedTxOutTokenIds: Set<TokenId> {
        Set(allTxOutTrackers
            .map { $0.knownTxOut.tokenId })
    }

    func cachedBalance(for tokenId: TokenId) -> Balance {
        let blockCount = knowableBlockCount
        let txOutValues = allTxOutTrackers
            .filter { $0.receivedAndUnspent(asOfBlockCount: blockCount) }
            .filter { $0.knownTxOut.tokenId == tokenId }
            .map { $0.knownTxOut.value }
        return Balance(values: txOutValues, blockCount: blockCount, tokenId: tokenId)
    }

    var cachedBalances: Balances {
        let balances = cachedTxOutTokenIds.map {
            cachedBalance(for: $0)
        }
        .reduce(into: [TokenId: Balance](), { result, balance in
            result[balance.tokenId] = balance
        })
        return Balances(balances: balances, blockCount: knowableBlockCount)
    }

    @available(*, deprecated, message:
        """
        Deprecated in favor of `cachedAccountActivity(for:TokenId)` which accepts a TokenId.
        `cachedAccountActivity` will assume the default TokenId == .MOB // UInt64(0)

        Get a set of all tokenIds that are in TxOuts owned by this account with:

        `MobileCoinClient(...).accountTokenIds // Set<TokenId>`
        """)

    var cachedAccountActivity: AccountActivity {
        cachedAccountActivity(for: .MOB)
    }

    func cachedAccountActivity(for tokenId: TokenId) -> AccountActivity {
        let blockCount = knowableBlockCount
        let txOuts = allTxOutTrackers
            .compactMap { OwnedTxOut($0, atBlockCount: blockCount) }
            .filter { $0.tokenId == tokenId }
        return AccountActivity(txOuts: txOuts, blockCount: blockCount, tokenId: tokenId)
    }

    var allCachedAccountActivity: AccountActivity {
        let blockCount = knowableBlockCount
        let txOuts = allTxOutTrackers
            .compactMap { OwnedTxOut($0, atBlockCount: blockCount) }
        return AccountActivity(txOuts: txOuts, blockCount: blockCount)
    }

    var ownedTxOuts: [KnownTxOut] {
        ownedTxOutsAndBlockCount.txOuts
    }

    var ownedTxOutsAndBlockCount: (txOuts: [KnownTxOut], blockCount: UInt64) {
        let knowableBlockCount = self.knowableBlockCount
        let txOuts = allTxOutTrackers
            .filter { $0.received(asOfBlockCount: knowableBlockCount) }
            .map { $0.knownTxOut }
        return (txOuts: txOuts, blockCount: knowableBlockCount)
    }

    func unspentTxOuts(tokenId: TokenId) -> [KnownTxOut] {
        unspentTxOutsAndBlockCount(tokenId: tokenId).txOuts
    }

    func unspentTxOutsAndBlockCount(
        tokenId: TokenId
    ) -> (txOuts: [KnownTxOut], blockCount: UInt64) {
        let knowableBlockCount = self.knowableBlockCount
        let txOuts = allTxOutTrackers
            .filter { $0.receivedAndUnspent(asOfBlockCount: knowableBlockCount) }
            .filter { $0.knownTxOut.tokenId == tokenId }
            .map { $0.knownTxOut }
        return (txOuts: txOuts, blockCount: knowableBlockCount)
    }

    func addTxOuts(_ txOuts: [KnownTxOut]) {
        allTxOutTrackers.append(contentsOf: txOuts.map { TxOutTracker($0) })
    }

    func addViewKeyScanResults(scannedBlockRanges: [Range<UInt64>], foundTxOuts: [KnownTxOut]) {
        addTxOuts(foundTxOuts)
        fogView.markBlocksAsScanned(blockRanges: scannedBlockRanges)
    }

    func cachedReceivedStatus(of receipt: Receipt)
        -> Result<Receipt.ReceivedStatus, InvalidInputError>
    {
        ownedTxOut(for: receipt).map {
            if let ownedTxOut = $0 {
                return .received(block: ownedTxOut.block)
            } else {
                let knownToBeNotReceivedBlockCount = allTxOutsFoundBlockCount
                guard receipt.txTombstoneBlockIndex > knownToBeNotReceivedBlockCount else {
                    return .tombstoneExceeded
                }
                return .notReceived(knownToBeNotReceivedBlockCount: knownToBeNotReceivedBlockCount)
            }
        }
    }

    /// Retrieves the `KnownTxOut`'s corresponding to `receipt` and verifies `receipt` is valid.
    private func ownedTxOut(for receipt: Receipt) -> Result<KnownTxOut?, InvalidInputError> {
        logger.debug(
            "Last received TxOut: TxOut pubkey: " +
                "\(redacting: ownedTxOuts.last?.publicKey.hexEncodedString() ?? "None")",
            logFunction: false)

        // First check if we've received the TxOut (either from Fog View or from view key scanning).
        // This has the benefit of providing a guarantee that the TxOut is owned by this account.
        guard let ownedTxOut = ownedTxOut(for: receipt.txOutPublicKeyTyped) else {
            return .success(nil)
        }

        // Make sure the Receipt data matches the TxOut found in the ledger. This verifies that the
        // public key, commitment, and masked value match.
        //
        // Note: This doesn't verify the confirmation number or tombstone block (since neither are
        // saved to the ledger).
        guard receipt.matchesTxOut(ownedTxOut) else {
            let errorMessage =
                "Receipt data doesn't match the corresponding TxOut found in the ledger. " +
                "Receipt: \(redacting: receipt.serializedData.base64EncodedString()) - " +
                "Account TxOut: \(redacting: ownedTxOut)"
            logger.error(errorMessage, sensitive: true, logFunction: false)
            return .failure(InvalidInputError(errorMessage))
        }

        // Verify that the confirmation number validates for this account key. This provides a
        // guarantee that the sender of the Receipt was the creator of the TxOut that we received.
        guard receipt.validateConfirmationNumber(accountKey: accountKey) else {
            let errorMessage = "Receipt confirmation number is invalid for this account. " +
                "Receipt: \(redacting: receipt.serializedData.base64EncodedString())"
            logger.error(errorMessage, sensitive: true, logFunction: false)
            return .failure(InvalidInputError(errorMessage))
        }

        return .success(ownedTxOut)
    }

    private func ownedTxOut(for txOutPublicKey: RistrettoPublic) -> KnownTxOut? {
        ownedTxOuts.first(where: { $0.publicKey == txOutPublicKey })
    }
}

extension Account {
    /// - Returns: `.failure` if `accountKey` doesn't use Fog.
    static func make(
        accountKey: AccountKey,
        syncChecker: FogSyncCheckable
    ) -> Result<Account, InvalidInputError> {
        guard let accountKey = AccountKeyWithFog(accountKey: accountKey) else {
            let errorMessage = "Accounts without fog URLs are not currently supported."
            logger.error(errorMessage, logFunction: false)
            return .failure(InvalidInputError(errorMessage))
        }
        return .success(Account(accountKey: accountKey, syncChecker: syncChecker))
    }
}

extension Account: CustomRedactingStringConvertible {
    var redactingDescription: String {
        publicAddress.redactingDescription
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

    var isSpent: Bool {
        keyImageTracker.isSpent
    }

    func receivedAndUnspent(asOfBlockCount blockCount: UInt64) -> Bool {
        received(asOfBlockCount: blockCount) && !spent(asOfBlockCount: blockCount)
    }

    func received(asOfBlockCount blockCount: UInt64) -> Bool {
        knownTxOut.block.index < blockCount
    }

    func spent(asOfBlockCount blockCount: UInt64) -> Bool {
        if case .spent = keyImageTracker.spentStatus.status(atBlockCount: blockCount) {
            return true
        }
        return false
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
