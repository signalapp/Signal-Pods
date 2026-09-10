//
// Copyright 2026 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest

@testable import LibSignalClient

class MessageBackupSizingTests: TestCaseBase {
    func testFlushIntervalTestValues() {
        XCTAssertEqual(MessageBackupSizing.flushInterval(uncompressedLength: 0), 8192)
        XCTAssertEqual(MessageBackupSizing.flushInterval(uncompressedLength: 65536), 9459)
        XCTAssertEqual(MessageBackupSizing.flushInterval(uncompressedLength: 1_048_576), 37837)
        XCTAssertEqual(MessageBackupSizing.flushInterval(uncompressedLength: 16_777_216), 151_348)
        XCTAssertEqual(MessageBackupSizing.flushInterval(uncompressedLength: 200_000_000), 522_557)

        XCTAssertEqual(
            MessageBackupSizing.flushInterval(
                uncompressedLength: 0,
                estimatedTotalUncompressedLength: 1_048_576
            ),
            26754
        )
        XCTAssertEqual(
            MessageBackupSizing.flushInterval(
                uncompressedLength: 0,
                estimatedTotalUncompressedLength: 16_777_216
            ),
            107_019
        )
    }

    func testEstimateHoldsAFixedIntervalUntilTheBackupCrossesIt() {
        let estimate: UInt64 = 16_777_216
        XCTAssertEqual(
            MessageBackupSizing.flushInterval(
                uncompressedLength: 0,
                estimatedTotalUncompressedLength: estimate
            ),
            MessageBackupSizing.flushInterval(
                uncompressedLength: estimate / 2,
                estimatedTotalUncompressedLength: estimate
            )
        )
        XCTAssertLessThan(
            MessageBackupSizing.flushInterval(
                uncompressedLength: 0,
                estimatedTotalUncompressedLength: estimate
            ),
            MessageBackupSizing.flushInterval(uncompressedLength: estimate)
        )

        // Past the estimate, the interval is the one that suits a backup ending here.
        XCTAssertEqual(
            MessageBackupSizing.flushInterval(
                uncompressedLength: 4 * estimate,
                estimatedTotalUncompressedLength: estimate
            ),
            MessageBackupSizing.flushInterval(
                uncompressedLength: 0,
                estimatedTotalUncompressedLength: 4 * estimate
            )
        )
    }

    func testSmallBackupsAllComeOutTheSameSize() {
        let compressedLength: UInt64 = 1000
        for _ in 0..<100 {
            XCTAssertEqual(
                compressedLength
                    + MessageBackupSizing.paddingSize(
                        maxIntervalBytes: 8192,
                        compressedLength: compressedLength
                    ),
                65536
            )
        }
    }
}
