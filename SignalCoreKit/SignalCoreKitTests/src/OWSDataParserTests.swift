//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import XCTest
import SignalCoreKit

class OWSDataParserTests: XCTestCase {

    func testDataParser1() {
        let someBytes: [UInt8] = [ 1, 2, 3, 4, 5, 6, 7, 8 ]
        let someData = NSData(bytes: someBytes, length: someBytes.count) as Data
        let dataParser = OWSDataParser(data: someData)
        
        XCTAssertEqual(dataParser.unreadByteCount, 8)
        XCTAssertFalse(dataParser.isEmpty)
        
        XCTAssertEqual(try dataParser.nextByte(), 1)
        XCTAssertEqual(dataParser.unreadByteCount, 7)
        XCTAssertFalse(dataParser.isEmpty)
        
        XCTAssertEqual(try dataParser.nextByte(), 2)
        XCTAssertEqual(dataParser.unreadByteCount, 6)
        XCTAssertFalse(dataParser.isEmpty)
        
        XCTAssertEqual(try dataParser.nextByte(), 3)
        XCTAssertEqual(dataParser.unreadByteCount, 5)
        XCTAssertFalse(dataParser.isEmpty)
    }
    
    func testDataParser2() {
        let someBytes: [UInt8] = [ 1, 2, 3, 4, 5, 6, 7, 8 ]
        let someData = NSData(bytes: someBytes, length: someBytes.count) as Data
        let dataParser = OWSDataParser(data: someData)
        
        XCTAssertEqual(dataParser.unreadByteCount, 8)
        XCTAssertFalse(dataParser.isEmpty)
        
        do {
            let readData = try dataParser.nextData(length: 8)
            XCTAssertEqual(someData, readData)
            XCTAssertEqual(dataParser.unreadByteCount, 0)
            XCTAssertTrue(dataParser.isEmpty)
        } catch {
            XCTFail("Error: \(error)")
            return
        }
        
        do {
            _ = try dataParser.nextByte()
            XCTFail("Read should have failed.")
        } catch {
            // This error is expected.
        }
    }
}
