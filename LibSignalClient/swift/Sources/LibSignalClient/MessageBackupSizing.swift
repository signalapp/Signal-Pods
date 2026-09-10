//
// Copyright 2026 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SignalFfi

/// Sizing decisions for a compressed backup stream.
///
/// The caller owns the compressor and does the flushing itself; this provides the arithmetic, so
/// that every platform makes the same choices.
public enum MessageBackupSizing {
    /// Uncompressed bytes to write before ending the current DEFLATE block.
    ///
    /// The interval grows with position, which is what lets a reasonable value
    /// be chosen without knowing the final size of the backup in advance. A
    /// caller that can estimate the total *uncompressed* length of the backup
    /// should pass it, and gets the fixed interval that suits a backup of that
    /// size. The uncompressed length of the previous backup is a good estimate.
    /// Passing a reasonable estimate will result in a smaller padded file, but
    /// the estimate does not need to be precise and the estimate has no impact
    /// on security.
    ///
    /// - Parameters:
    ///  - uncompressedLength: uncompressed bytes written since the chat item region began.
    ///  - estimatedTotalUncompressedLength: estimated total uncompressed length, if known.
    public static func flushInterval(
        uncompressedLength: UInt64,
        estimatedTotalUncompressedLength: UInt64? = nil
    ) -> UInt64 {
        return failOnError {
            try invokeFnReturningInteger {
                signal_message_backup_sizing_flush_interval(
                    $0,
                    uncompressedLength,
                    estimatedTotalUncompressedLength ?? 0
                )
            }
        }
    }

    /// Number of zero bytes to append to a finished backup stream.
    ///
    /// - Parameters:
    ///  - maxIntervalBytes: the largest DEFLATE block the writer *actually produced* in the chat
    ///    item region, in uncompressed bytes.
    ///  - compressedLength: length of the compressed stream, before padding.
    public static func paddingSize(maxIntervalBytes: UInt64, compressedLength: UInt64) -> UInt64 {
        return failOnError {
            try invokeFnReturningInteger {
                signal_message_backup_sizing_padding_size($0, maxIntervalBytes, compressedLength)
            }
        }
    }
}
