//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import XCTest
@testable import SignalCoreKit

class StringSanitizerTests: XCTestCase {
    func testEmpty() {
        let string = ""
        let sanitizer = StringSanitizer(string)
        XCTAssertFalse(sanitizer.needsSanitization)
        XCTAssertEqual(sanitizer.sanitized, string)
    }

    func testASCII() {
        let string = "abc"
        let sanitizer = StringSanitizer(string)
        XCTAssertFalse(sanitizer.needsSanitization)
        XCTAssertEqual(sanitizer.sanitized, string)
    }

    func testCombiningMarks() {
        let string = "abx̧c"
        let sanitizer = StringSanitizer(string)
        XCTAssertFalse(sanitizer.needsSanitization)
        XCTAssertEqual(sanitizer.sanitized, string)
    }

    func testEmoji() {
        let string = "a👩🏿‍❤️‍💋‍👩🏻b"
        let sanitizer = StringSanitizer(string)
        XCTAssertFalse(sanitizer.needsSanitization)
        XCTAssertEqual(sanitizer.sanitized, string)
    }

    func testZalgo() {
        let string = "x̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝abx̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝x̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝👩🏿‍❤️‍💋‍👩🏻cx̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝"
        let sanitizer = StringSanitizer(string)
        XCTAssertTrue(sanitizer.needsSanitization)
        let expected = "�ab��👩🏿‍❤️‍💋‍👩🏻c�"
        XCTAssertEqual(sanitizer.sanitized, expected)
    }

    func testSingleZalgo() {
        let string = "x̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝"
        let sanitizer = StringSanitizer(string)
        XCTAssertTrue(sanitizer.needsSanitization)
        let expected = "�"
        XCTAssertEqual(sanitizer.sanitized, expected)
    }

    func testTwoZalgo() {
        let string = "x̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝x̸̢̧̛̙̝͈͈̖̳̗̰̆̈́̆̿̈́̅̽͆̈́̿̔͌̚͝"
        let sanitizer = StringSanitizer(string)
        XCTAssertTrue(sanitizer.needsSanitization)
        let expected = "��"
        XCTAssertEqual(sanitizer.sanitized, expected)
    }
}
