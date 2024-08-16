// swiftlint:disable:this file_name
// swiftlint:disable implicit_getter
//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

// MARK: - External

extension External_RistrettoPrivate {
    init<DataType: DataConvertible>(_ data: DataType) {
        self.init()
        self.data = data.data
    }
}

extension External_CompressedRistretto {
    init<DataType: DataConvertible>(_ data: DataType) {
        self.init()
        self.data = data.data
    }
}

extension External_KeyImage {
    init<DataType: DataConvertible>(_ data: DataType) {
        self.init()
        self.data = data.data
    }
}

extension External_MaskedAmount {
    init<CommitmentType: DataConvertible>(
        commitment: CommitmentType,
        maskedValue: UInt64,
        maskedTokenId: Data
    ) {
        self.init()
        self.commitment = External_CompressedRistretto(commitment)
        self.maskedValue = maskedValue
        self.maskedTokenID = maskedTokenId
    }
}

extension External_EncryptedFogHint {
    init<DataType: DataConvertible>(_ data: DataType) {
        self.init()
        self.data = data.data
    }
}

// MARK: - Fog Common

extension FogCommon_BlockRange {
    init(_ range: Range<UInt64>) {
        self.init()
        self.startBlock = range.lowerBound
        self.endBlock = range.upperBound
    }

    var range: Range<UInt64> {
        get { startBlock..<endBlock }
        set {
            startBlock = newValue.lowerBound
            endBlock = newValue.upperBound
        }
    }
}

// MARK: - Fog View

extension FogView_RngRecord {
    init(nonce fogRngKey: FogRngKey, startBlock: UInt64) {
        self.init()
        self.pubkey = KexRng_KexRngPubkey(fogRngKey)
        self.startBlock = startBlock
    }
}

extension FogView_TxOutSearchResult {
    var resultCodeEnum: FogView_TxOutSearchResultCode {
        get {
            FogView_TxOutSearchResultCode(rawValue: Int(resultCode))
                ?? .UNRECOGNIZED(Int(resultCode))
        }
        set { resultCode = UInt32(newValue.rawValue) }
    }
}

extension FogView_TxOutRecord {
    var timestampDate: Date? {
        get { timestamp != UInt64.max ? Date(timeIntervalSince1970: TimeInterval(timestamp)) : nil }
        set {
            if let newValue = newValue {
                timestamp = UInt64(newValue.timeIntervalSince1970)
            } else {
                timestamp = UInt64.max
            }
        }
    }
}

extension FogView_TxOutRecordLegacy {
    var timestampDate: Date? {
        get { timestamp != UInt64.max ? Date(timeIntervalSince1970: TimeInterval(timestamp)) : nil }
        set {
            if let newValue = newValue {
                timestamp = UInt64(newValue.timeIntervalSince1970)
            } else {
                timestamp = UInt64.max
            }
        }
    }
}

// MARK: - Fog Ledger

extension FogLedger_OutputResult {
    var resultCodeEnum: FogLedger_OutputResultCode {
        get {
            FogLedger_OutputResultCode(rawValue: Int(resultCode)) ?? .UNRECOGNIZED(Int(resultCode))
        }
        set { resultCode = UInt32(newValue.rawValue) }
    }
}

extension FogLedger_KeyImageResult {
    var timestampDate: Date {
        get { Date(timeIntervalSince1970: TimeInterval(timestamp)) }
        set { timestamp = UInt64(newValue.timeIntervalSince1970) }
    }

    var timestampResultCodeEnum: Watcher_TimestampResultCode {
        get {
            Watcher_TimestampResultCode(rawValue: Int(timestampResultCode))
                ?? .UNRECOGNIZED(Int(timestampResultCode))
        }
        set { timestampResultCode = UInt32(newValue.rawValue) }
    }

    var keyImageResultCodeEnum: FogLedger_KeyImageResultCode {
        get {
            FogLedger_KeyImageResultCode(rawValue: Int(keyImageResultCode))
                ?? .UNRECOGNIZED(Int(keyImageResultCode))
        }
        set { keyImageResultCode = UInt32(newValue.rawValue) }
    }

    var timestampStatus: BlockMetadata.TimestampStatus? {
        switch timestampResultCodeEnum {
        case .timestampFound:
            return .known(timestamp: timestampDate)
        case .unavailable:
            return .unavailable
        case .watcherBehind, .watcherDatabaseError, .blockIndexOutOfBounds:
            return .temporarilyUnknown
        case .unusedField, .UNRECOGNIZED:
            return nil
        }
    }
}

extension FogLedger_BlockRequest {
    var rangeValues: [Range<UInt64>] {
        get { ranges.map { $0.startBlock..<$0.endBlock } }
        set { ranges = newValue.map { FogCommon_BlockRange($0) } }
    }
}

extension FogLedger_BlockData {
    var timestampDate: Date {
        get { Date(timeIntervalSince1970: TimeInterval(timestamp)) }
        set { timestamp = UInt64(newValue.timeIntervalSince1970) }
    }

    var timestampResultCodeEnum: Watcher_TimestampResultCode {
        get {
            Watcher_TimestampResultCode(rawValue: Int(timestampResultCode))
                ?? .UNRECOGNIZED(Int(timestampResultCode))
        }
        set { timestampResultCode = UInt32(newValue.rawValue) }
    }

    var timestampStatus: BlockMetadata.TimestampStatus? {
        switch timestampResultCodeEnum {
        case .timestampFound:
            return .known(timestamp: timestampDate)
        case .unavailable:
            return .unavailable
        case .watcherBehind, .watcherDatabaseError, .blockIndexOutOfBounds:
            return .temporarilyUnknown
        case .unusedField, .UNRECOGNIZED:
            return nil
        }
    }

    var metadata: BlockMetadata {
        BlockMetadata(index: index, timestampStatus: timestampStatus)
    }
}

extension FogLedger_TxOutResult {
    var timestampDate: Date? {
        get { timestamp != UInt64.max ? Date(timeIntervalSince1970: TimeInterval(timestamp)) : nil }
        set {
            if let newValue = newValue {
                timestamp = UInt64(newValue.timeIntervalSince1970)
            } else {
                timestamp = UInt64.max
            }
        }
    }
}
