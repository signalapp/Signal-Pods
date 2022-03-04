//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation
import XCTest
import SignalCoreKit

class PromiseTests: XCTestCase {
    func test_simpleQueueChaining() {
        let guaranteeExpectation = expectation(description: "Expect guarantee on global queue")
        let mapExpectation = expectation(description: "Expect map on global queue")
        let doneExpectation = expectation(description: "Expect done on main queue")

        firstly(on: .global()) { () -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.global()))
            guaranteeExpectation.fulfill()
            return "abc"
        }.map(on: .global()) { string -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.global()))
            mapExpectation.fulfill()
            return string + "xyz"
        }.done { string in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.main))
            XCTAssertEqual(string, "abcxyz")
            doneExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_mixedQueueChaining() {
        let guaranteeExpectation = expectation(description: "Expect guarantee on global queue")
        let mapExpectation = expectation(description: "Expect map on main queue")
        let doneExpectation = expectation(description: "Expect done on main queue")

        firstly(on: .global()) { () -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.global()))
            guaranteeExpectation.fulfill()
            return "abc"
        }.map(on: .main) { string -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.main))
            mapExpectation.fulfill()
            return string + "xyz"
        }.done { string in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.main))
            XCTAssertEqual(string, "abcxyz")
            doneExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_queueChainingWithErrors() {
        let guaranteeExpectation = expectation(description: "Expect guarantee on global queue")
        let mapExpectation = expectation(description: "Expect map on main queue")
        let catchExpectation = expectation(description: "Expect catch on main queue")

        enum SimpleError: String, Error {
            case assertion
        }

        firstly(on: .global()) { () -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.global()))
            guaranteeExpectation.fulfill()
            return "abc"
        }.map { _ -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.main))
            mapExpectation.fulfill()
            throw SimpleError.assertion
        }.done(on: .main) { _ in
            XCTAssert(false, "Done should never be called.")
        }.catch { error in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.main))
            XCTAssertEqual(error as? SimpleError, SimpleError.assertion)
            catchExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_recovery() {
        let doneExpectation = expectation(description: "Done")

        firstly(on: .global()) { () -> String in
            return "abc"
        }.map { _ -> String in
            throw OWSGenericError("some error")
        }.recover { _ in
            return .value("xyz")
        }.done { string in
            XCTAssertEqual(string, "xyz")
            doneExpectation.fulfill()
        }.catch { _ in
            XCTAssert(false, "Catch should never be called.")
        }

        waitForExpectations(timeout: 5)
    }

    func test_ensure() {
        let ensureExpectation1 = expectation(description: "ensure on success")
        let ensureExpectation2 = expectation(description: "ensure on failure")

        firstly(on: .global()) { () -> String in
            return "abc"
        }.map { _ -> String in
            throw OWSGenericError("some error")
        }.done { _ in
            XCTAssert(false, "Done should never be called.")
        }.ensure {
            ensureExpectation1.fulfill()
        }.catch { _ in
            XCTAssert(true, "Catch should be called.")
        }

        firstly(on: .global()) { () -> String in
            return "abc"
        }.map { string -> String in
            return string + "xyz"
        }.done { _ in
            XCTAssert(true, "Done should be called.")
        }.ensure {
            ensureExpectation2.fulfill()
        }.catch { _ in
            XCTAssert(false, "Catch should never be called.")
        }

        waitForExpectations(timeout: 5)
    }

    func test_whenFullfilled() {
        let when1 = expectation(description: "when1")
        let when2 = expectation(description: "when2")

        Promise.when(fulfilled: [
            firstly(on: .global()) { "abc" },
            firstly(on: .main) { "xyz" }.map { $0 + "abc" }
        ]).done {
            when1.fulfill()
        }.catch { _ in
            XCTAssert(false, "Catch should never be called.")
        }

        Promise.when(fulfilled: [
            firstly(on: .global()) { "abc" },
            firstly(on: .main) { "xyz" }.map { _ in throw OWSGenericError("an error") }
        ]).done {
            XCTAssert(false, "Done should never be called.")
        }.catch { _ in
            when2.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_when() {
        let when1 = expectation(description: "when1")
        let when2 = expectation(description: "when2")

        var chainOneCounter = 0

        Promise.when(resolved: [
            firstly(on: .main) { () -> String in
                chainOneCounter += 1
                throw OWSGenericError("error")
            },
            firstly(on: .global()) { () -> String in
                sleep(2)
                chainOneCounter += 1
                return "abc"
            }
        ]).done { _ in
            XCTAssertEqual(chainOneCounter, 2)
            when1.fulfill()
        }

        var chainTwoCounter = 0

        Promise.when(fulfilled: [
            firstly(on: .main) { () -> String in
                chainTwoCounter += 1
                throw OWSGenericError("error")
            },
            firstly(on: .global()) { () -> String in
                sleep(2)
                chainTwoCounter += 1
                return "abc"
            }
        ]).done {
            XCTAssert(false, "Done should never be called.")
        }.catch { _ in
            XCTAssertEqual(chainTwoCounter, 1)
            when2.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_wait() throws {
        XCTAssertEqual(firstly(on: .global()) { () -> Int in
            sleep(1)
            return 5000
        }.wait(), 5000)

        XCTAssertThrowsError(try firstly(on: .global()) { () -> Int in
            sleep(1)
            throw OWSGenericError("An error")
        }.wait())
    }

    func test_timeout() {
        let expectTimeout = expectation(description: "timeout")

        firstly(on: .global()) { () -> String in
            sleep(15)
            return "default"
        }.timeout(
            seconds: 1,
            substituteValue: "substitute"
        ).done { result in
            XCTAssertEqual(result, "substitute")
            expectTimeout.fulfill()
        }.cauterize()

        let expectNoTimeout = expectation(description: "noTimeout")

        firstly(on: .global()) { () -> String in
            sleep(1)
            return "default"
        }.timeout(
            seconds: 3,
            substituteValue: "substitute"
        ).done { result in
            XCTAssertEqual(result, "default")
            expectNoTimeout.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5)
    }

    func test_anyPromise() {
        let anyPromiseExpectation = expectation(description: "Expect anyPromise on global queue")
        let mapExpectation = expectation(description: "Expect map on global queue")
        let doneExpectation = expectation(description: "Expect done on main queue")

        AnyPromise(firstly(on: .global()) { () -> String in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.global()))
            anyPromiseExpectation.fulfill()
            return "abc"
        }).map(on: .global()) { string -> String in
            XCTAssertTrue(string is String)
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.global()))
            mapExpectation.fulfill()
            return (string as! String) + "xyz"
        }.done { string in
            XCTAssertTrue(DispatchQueueIsCurrentQueue(.main))
            XCTAssertEqual(string, "abcxyz")
            doneExpectation.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5)
    }

    func test_deepPromiseChain() {
        var sharedValue = 0
        var promise = firstly(on: .global()) {
            sharedValue += 1
        }

        let testDepth = 1000
        for _ in 0..<testDepth {
            promise = promise.then(on: .global()) {
                sharedValue += 1
                return .value(())
            }
        }
        promise.done(on: .global()) {
            sharedValue += 1
        }.wait()

        XCTAssertEqual(sharedValue, 1 + testDepth + 1)
    }

    func test_promiseUsingResultPropertyInObserverCallback() throws {
        let (promise, future) = Promise<Int>.pending()

        var doneCalled = false
        _ = promise.done(on: .main) { argValue in
            switch promise.result {
            case .success(let resultValue):
                XCTAssertEqual(resultValue, argValue)
            case .failure(_):
                XCTFail("unexpected failure")
            case nil:
                XCTFail("how did done() get called without the promise being sealed?")
            }
            doneCalled = true
        }

        future.resolve(10)
        XCTAssert(doneCalled)
        XCTAssertEqual(try future.result?.get(), 10)
    }
}
