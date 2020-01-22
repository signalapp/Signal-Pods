//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import XCTest
import SignalCoreKit

class CryptographyTestsSwift: XCTestCase {

    private func Assert(unpaddedSize: UInt, hasPaddedSize paddedSize: UInt, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(paddedSize, Cryptography.paddedSize(unpaddedSize: unpaddedSize), file: file, line: line)
    }

    private func AssertFalse(unpaddedSize: UInt, hasPaddedSize paddedSize: UInt, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotEqual(paddedSize, Cryptography.paddedSize(unpaddedSize: unpaddedSize), file: file, line: line)
    }

    func test_paddedSizeSpotChecks() {
        Assert(unpaddedSize: 1, hasPaddedSize: 541)
        Assert(unpaddedSize: 12, hasPaddedSize: 541)
        Assert(unpaddedSize: 123, hasPaddedSize: 541)
        Assert(unpaddedSize: 1_234, hasPaddedSize: 1_240)
        Assert(unpaddedSize: 12_345, hasPaddedSize: 12_903)
        Assert(unpaddedSize: 123_456, hasPaddedSize: 127_826)
        Assert(unpaddedSize: 1_234_567, hasPaddedSize: 1_266_246)
        Assert(unpaddedSize: 12_345_678, hasPaddedSize: 12_543_397)
        Assert(unpaddedSize: 123_456_789, hasPaddedSize: 124_254_533)
    }

    func test_spotCheckBucketBoundaries() {
        // first bucket
        Assert(unpaddedSize: 0, hasPaddedSize: 541)
        Assert(unpaddedSize: 1, hasPaddedSize: 541)
        Assert(unpaddedSize: 540, hasPaddedSize: 541)
        Assert(unpaddedSize: 541, hasPaddedSize: 541)

        // second bucket
        Assert(unpaddedSize: 542, hasPaddedSize: 568)
        Assert(unpaddedSize: 567, hasPaddedSize: 568)
        Assert(unpaddedSize: 568, hasPaddedSize: 568)

        // third bucket
        Assert(unpaddedSize: 569, hasPaddedSize: 596)
        Assert(unpaddedSize: 595, hasPaddedSize: 596)
        Assert(unpaddedSize: 596, hasPaddedSize: 596)

        // 100th bucket
        Assert(unpaddedSize: 64_562, hasPaddedSize: 67_789)
        Assert(unpaddedSize: 67_788, hasPaddedSize: 67_789)
        Assert(unpaddedSize: 67_789, hasPaddedSize: 67_789)

        // 101st bucket
        Assert(unpaddedSize: 67_790, hasPaddedSize: 71_178)
        Assert(unpaddedSize: 71_177, hasPaddedSize: 71_178)
        Assert(unpaddedSize: 71_178, hasPaddedSize: 71_178)

        // 249th bucket
        Assert(unpaddedSize: 92_720_647, hasPaddedSize: 97_356_678)
        Assert(unpaddedSize: 97_356_677, hasPaddedSize: 97_356_678)
        Assert(unpaddedSize: 97_356_678, hasPaddedSize: 97_356_678)
    }

    func test_paddedSizeBucketsRounding() {
        var prevBucketMax: UInt = 541
        for _ in 2..<401 {
            let bucketMax = UInt(floor(pow(1.05, ceil(log(Double(prevBucketMax) + 1)/log(1.05)))))

            // This test is mostly reflexive, but checks rounding errors around the bucket edges.
            Assert(unpaddedSize: bucketMax, hasPaddedSize: bucketMax)
            Assert(unpaddedSize: bucketMax - 1, hasPaddedSize: bucketMax)
            AssertFalse(unpaddedSize: bucketMax + 1, hasPaddedSize: bucketMax)

            prevBucketMax = bucketMax
        }
    }

    func test_SHA256HMACSIV() throws {
        let key = Data.data(fromHex: "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F")!
        let data = Data.data(fromHex: "202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F")!

        let (iv, cipherText) = try Cryptography.encryptSHA256HMACSIV(data: data, key: key)
        let decryptedData = try Cryptography.decryptSHA256HMACSIV(iv: iv, cipherText: cipherText, key: key)

        XCTAssertEqual(data, decryptedData)
        XCTAssertEqual(iv, Data.data(fromHex: "f27036915a60d704b04d452ef0d55a5d")!)
        XCTAssertEqual(cipherText, Data.data(fromHex: "1668e7d91339daba9c950d985b7556471d13cc609e59eec62fb1ce27f5c5a342")!)
    }
}
