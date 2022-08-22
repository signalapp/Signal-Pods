//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol FogSyncCheckable {
    var viewsHighestKnownBlock: UInt64 { get }
    var ledgersHighestKnownBlock: UInt64 { get }
    var consensusHighestKnownBlock: UInt64 { get }
    var currentBlockIndex: UInt64 { get }
    var maxAllowedBlockDelta: PositiveUInt64 { get }

    func inSync() -> Result<(), FogSyncError>
    func setLedgersHighestKnownBlock(_:UInt64)
    func setViewsHighestKnownBlock(_:UInt64)
    func setConsensusHighestKnownBlock(_:UInt64)
}

extension FogSyncCheckable {
    func inSync() -> Result<(), FogSyncError> {
        guard viewLedgerOutOfSync == false else {
            return .failure(.viewLedgerOutOfSync(viewsHighestKnownBlock, ledgersHighestKnownBlock))
        }
        guard consensusOutOfSync == false else {
            return .failure(.consensusOutOfSync(consensusHighestKnownBlock, currentBlockIndex))
        }
        return .success(())
    }

    var currentBlockIndex: UInt64 {
        min(ledgersHighestKnownBlock, viewsHighestKnownBlock)
    }

    private var viewLedgerOutOfSync: Bool {
        // max(...) - min(...) ensures the result is always a positive integer that won't overflow
        //
        // Other possible constructions like:
        //
        // ```
        //     abs(Int64(UInt64 - UInt64))  // or...
        //     abs(UInt64 - UInt64) // where the first UInt64 is smaller than the second
        // ```
        //
        // would cause arithmetic overflow exceptions at runtime.
        //

        UInt64(
            max(ledgersHighestKnownBlock, viewsHighestKnownBlock) -
            min(ledgersHighestKnownBlock, viewsHighestKnownBlock)
        ) > maxAllowedBlockDelta.value
    }

    private var consensusOutOfSync: Bool {
        // Consensus is only considered out of sync when its ahead of "fog's current block index" &&
        // the delta is greater than the max allowed delta.
        // The first boolean case short-circuits the second which avoids any chance of overflow.
        consensusHighestKnownBlock > currentBlockIndex &&
            UInt64(consensusHighestKnownBlock - currentBlockIndex) > maxAllowedBlockDelta.value
    }
}

class FogSyncChecker: FogSyncCheckable {
    var viewsHighestKnownBlock: UInt64 = 0
    var ledgersHighestKnownBlock: UInt64 = 0
    var consensusHighestKnownBlock: UInt64 = 0

    let maxAllowedBlockDelta: PositiveUInt64

    init() {
        guard let maxAllowedBlockDelta = PositiveUInt64(10) else {
            logger.fatalError("Should never be reached as 10 > 0")
        }
        self.maxAllowedBlockDelta = maxAllowedBlockDelta
    }

    func setViewsHighestKnownBlock(_ value: UInt64) {
        viewsHighestKnownBlock = value
    }

    func setLedgersHighestKnownBlock(_ value: UInt64) {
        ledgersHighestKnownBlock = value
    }

    func setConsensusHighestKnownBlock(_ value: UInt64) {
        consensusHighestKnownBlock = value
    }
}

public enum FogSyncError: Error {
    case viewLedgerOutOfSync(UInt64, UInt64)
    case consensusOutOfSync(UInt64, UInt64)
}

extension FogSyncError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .viewLedgerOutOfSync(viewBlockIndex, ledgerBlockIndex):
            return "Fog view and ledger block indices are out of sync. " +
                "Try again later. View index: \(viewBlockIndex), Ledger index: \(ledgerBlockIndex)"
        case let .consensusOutOfSync(consensusBlockIndex, currentBlockIndex):
            return "Fog has not finished syncing with Consensus. " +
                "Try again later (Block index \(currentBlockIndex) / \(consensusBlockIndex)."
        }
    }
}
