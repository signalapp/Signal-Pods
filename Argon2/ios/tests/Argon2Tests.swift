import Foundation
import XCTest
import Argon2

// Test data originated in Argon2 test.c
class Argon2Tests: XCTestCase {
    func test_argon2i_v10() throws {
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "f6c4db4a54e2a370627aff3db6176b94a2a209a62c8e36152711802f7b30c694",
            encodedString: "$argon2i$m=65536,t=2,p=1$c29tZXNhbHQ$9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 2,
            memory: 20,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "9690ec55d28d3ed32562f2e73ea62b02b018757643a2ae6e79528459de8106e9",
            encodedString: "$argon2i$m=1048576,t=2,p=1$c29tZXNhbHQ$lpDsVdKNPtMlYvLnPqYrArAYdXZDoq5ueVKEWd6BBuk",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 2,
            memory: 18,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "3e689aaa3d28a77cf2bc72a51ac53166761751182f1ee292e3f677a7da4c2467",
            encodedString: "$argon2i$m=262144,t=2,p=1$c29tZXNhbHQ$Pmiaqj0op3zyvHKlGsUxZnYXURgvHuKS4/Z3p9pMJGc",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 2,
            memory: 8,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "fd4dd83d762c49bdeaf57c47bdcd0c2f1babf863fdeb490df63ede9975fccf06",
            encodedString: "$argon2i$m=256,t=2,p=1$c29tZXNhbHQ$/U3YPXYsSb3q9XxHvc0MLxur+GP960kN9j7emXX8zwY",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 2,
            memory: 8,
            threads: 2,
            password: "password",
            salt: "somesalt",
            hexString: "b6c11560a6a9d61eac706b79a2f97d68b4463aa3ad87e00c07e2b01e90c564fb",
            encodedString: "$argon2i$m=256,t=2,p=2$c29tZXNhbHQ$tsEVYKap1h6scGt5ovl9aLRGOqOth+AMB+KwHpDFZPs",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 1,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "81630552b8f3b1f48cdb1992c4c678643d490b2b5eb4ff6c4b3438b5621724b2",
            encodedString: "$argon2i$m=65536,t=1,p=1$c29tZXNhbHQ$gWMFUrjzsfSM2xmSxMZ4ZD1JCytetP9sSzQ4tWIXJLI",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 4,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "f212f01615e6eb5d74734dc3ef40ade2d51d052468d8c69440a3a1f2c1c2847b",
            encodedString: "$argon2i$m=65536,t=4,p=1$c29tZXNhbHQ$8hLwFhXm6110c03D70Ct4tUdBSRo2MaUQKOh8sHChHs",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "differentpassword",
            salt: "somesalt",
            hexString: "e9c902074b6754531a3a0be519e5baf404b30ce69b3f01ac3bf21229960109a3",
            encodedString: "$argon2i$m=65536,t=2,p=1$c29tZXNhbHQ$6ckCB0tnVFMaOgvlGeW69ASzDOabPwGsO/ISKZYBCaM",
            variant: .i,
            version: .v10
        )
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "diffsalt",
            hexString: "79a103b90fe8aef8570cb31fc8b22259778916f8336b7bdac3892569d4f1c497",
            encodedString: "$argon2i$m=65536,t=2,p=1$ZGlmZnNhbHQ$eaEDuQ/orvhXDLMfyLIiWXeJFvgza3vaw4kladTxxJc",
            variant: .i,
            version: .v10
        )
    }

    func test_argon2i_v10_verifyErrors() {
        /* Handle an invalid encoding correctly (it is missing a $) */
        XCTAssertThrowsExpectedError(try Argon2.verify(
            encoded: "$argon2i$m=65536,t=2,p=1c29tZXNhbHQ$9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ",
            password: "password".data(using: .utf8)!,
            variant: .i
        ), Argon2.Error.decodingFailed)

        /* Handle an invalid encoding correctly (it is missing a $) */
        XCTAssertThrowsExpectedError(try Argon2.verify(
            encoded: "$argon2i$m=65536,t=2,p=1$c29tZXNhbHQ9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ",
            password: "password".data(using: .utf8)!,
            variant: .i
        ), Argon2.Error.decodingFailed)

        /* Handle an invalid encoding correctly (salt is too short) */
        XCTAssertThrowsExpectedError(try Argon2.verify(
            encoded: "$argon2i$m=65536,t=2,p=1$$9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ",
            password: "password".data(using: .utf8)!,
            variant: .i
        ), Argon2.Error.saltTooShort)

        /* Handle an mismatching hash (the encoded password is "passwore") */
        XCTAssertFalse(try! Argon2.verify(
            encoded: "$argon2i$m=65536,t=2,p=1$c29tZXNhbHQ$b2G3seW+uPzerwQQC+/E1K50CLLO7YXy0JRcaTuswRo",
            password: "password".data(using: .utf8)!,
            variant: .i
        ))
    }

    func test_argon2i_vLatest() throws {
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "c1628832147d9720c5bd1cfd61367078729f6dfb6f8fea9ff98158e0d7816ed0",
            encodedString: "$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$wWKIMhR9lyDFvRz9YTZweHKfbftvj+qf+YFY4NeBbtA",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 20,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "d1587aca0922c3b5d6a83edab31bee3c4ebaef342ed6127a55d19b2351ad1f41",
            encodedString: "$argon2i$v=19$m=1048576,t=2,p=1$c29tZXNhbHQ$0Vh6ygkiw7XWqD7asxvuPE667zQu1hJ6VdGbI1GtH0E",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 18,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "296dbae80b807cdceaad44ae741b506f14db0959267b183b118f9b24229bc7cb",
            encodedString: "$argon2i$v=19$m=262144,t=2,p=1$c29tZXNhbHQ$KW266AuAfNzqrUSudBtQbxTbCVkmexg7EY+bJCKbx8s",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 8,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "89e9029f4637b295beb027056a7336c414fadd43f6b208645281cb214a56452f",
            encodedString: "$argon2i$v=19$m=256,t=2,p=1$c29tZXNhbHQ$iekCn0Y3spW+sCcFanM2xBT63UP2sghkUoHLIUpWRS8",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 8,
            threads: 2,
            password: "password",
            salt: "somesalt",
            hexString: "4ff5ce2769a1d7f4c8a491df09d41a9fbe90e5eb02155a13e4c01e20cd4eab61",
            encodedString: "$argon2i$v=19$m=256,t=2,p=2$c29tZXNhbHQ$T/XOJ2mh1/TIpJHfCdQan76Q5esCFVoT5MAeIM1Oq2E",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 1,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "d168075c4d985e13ebeae560cf8b94c3b5d8a16c51916b6f4ac2da3ac11bbecf",
            encodedString: "$argon2i$v=19$m=65536,t=1,p=1$c29tZXNhbHQ$0WgHXE2YXhPr6uVgz4uUw7XYoWxRkWtvSsLaOsEbvs8",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 4,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "aaa953d58af3706ce3df1aefd4a64a84e31d7f54175231f1285259f88174ce5b",
            encodedString: "$argon2i$v=19$m=65536,t=4,p=1$c29tZXNhbHQ$qqlT1YrzcGzj3xrv1KZKhOMdf1QXUjHxKFJZ+IF0zls",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "differentpassword",
            salt: "somesalt",
            hexString: "14ae8da01afea8700c2358dcef7c5358d9021282bd88663a4562f59fb74d22ee",
            encodedString: "$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$FK6NoBr+qHAMI1jc73xTWNkCEoK9iGY6RWL1n7dNIu4",
            variant: .i,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "diffsalt",
            hexString: "b0357cccfbef91f3860b0dba447b2348cbefecadaf990abfe9cc40726c521271",
            encodedString: "$argon2i$v=19$m=65536,t=2,p=1$ZGlmZnNhbHQ$sDV8zPvvkfOGCw26RHsjSMvv7K2vmQq/6cxAcmxSEnE",
            variant: .i,
            version: .latest
        )
    }

    func test_argon2i_vLatest_verifyError() {
        /* Handle an invalid encoding correctly (it is missing a $) */
        XCTAssertThrowsExpectedError(try Argon2.verify(
            encoded: "$argon2i$v=19$m=65536,t=2,p=1c29tZXNhbHQ$wWKIMhR9lyDFvRz9YTZweHKfbftvj+qf+YFY4NeBbtA",
            password: "password".data(using: .utf8)!,
            variant: .i
        ), Argon2.Error.decodingFailed)

        /* Handle an invalid encoding correctly (it is missing a $) */
        XCTAssertThrowsExpectedError(try Argon2.verify(
            encoded: "$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQwWKIMhR9lyDFvRz9YTZweHKfbftvj+qf+YFY4NeBbtA",
            password: "password".data(using: .utf8)!,
            variant: .i
        ), Argon2.Error.decodingFailed)

        /* Handle an invalid encoding correctly (salt is too short) */
        XCTAssertThrowsExpectedError(try Argon2.verify(
            encoded: "$argon2i$v=19$m=65536,t=2,p=1$$9sTbSlTio3Biev89thdrlKKiCaYsjjYVJxGAL3swxpQ",
            password: "password".data(using: .utf8)!,
            variant: .i
        ), Argon2.Error.saltTooShort)

        /* Handle an mismatching hash (the encoded password is "passwore") */
        XCTAssertFalse(try! Argon2.verify(
            encoded: "$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$8iIuixkI73Js3G1uMbezQXD0b8LG4SXGsOwoQkdAQIM",
            password: "password".data(using: .utf8)!,
            variant: .i
        ))
    }

    func test_argon2id_vLatest() throws {
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "09316115d5cf24ed5a15a31a3ba326e5cf32edc24702987c02b6566f61913cf7",
            encodedString: "$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$CTFhFdXPJO1aFaMaO6Mm5c8y7cJHAph8ArZWb2GRPPc",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 18,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "78fe1ec91fb3aa5657d72e710854e4c3d9b9198c742f9616c2f085bed95b2e8c",
            encodedString: "$argon2id$v=19$m=262144,t=2,p=1$c29tZXNhbHQ$eP4eyR+zqlZX1y5xCFTkw9m5GYx0L5YWwvCFvtlbLow",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 8,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "9dfeb910e80bad0311fee20f9c0e2b12c17987b4cac90c2ef54d5b3021c68bfe",
            encodedString: "$argon2id$v=19$m=256,t=2,p=1$c29tZXNhbHQ$nf65EOgLrQMR/uIPnA4rEsF5h7TKyQwu9U1bMCHGi/4",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 8,
            threads: 2,
            password: "password",
            salt: "somesalt",
            hexString: "6d093c501fd5999645e0ea3bf620d7b8be7fd2db59c20d9fff9539da2bf57037",
            encodedString: "$argon2id$v=19$m=256,t=2,p=2$c29tZXNhbHQ$bQk8UB/VmZZF4Oo79iDXuL5/0ttZwg2f/5U52iv1cDc",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 1,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "f6a5adc1ba723dddef9b5ac1d464e180fcd9dffc9d1cbf76cca2fed795d9ca98",
            encodedString: "$argon2id$v=19$m=65536,t=1,p=1$c29tZXNhbHQ$9qWtwbpyPd3vm1rB1GThgPzZ3/ydHL92zKL+15XZypg",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 4,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "somesalt",
            hexString: "9025d48e68ef7395cca9079da4c4ec3affb3c8911fe4f86d1a2520856f63172c",
            encodedString: "$argon2id$v=19$m=65536,t=4,p=1$c29tZXNhbHQ$kCXUjmjvc5XMqQedpMTsOv+zyJEf5PhtGiUghW9jFyw",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "differentpassword",
            salt: "somesalt",
            hexString: "0b84d652cf6b0c4beaef0dfe278ba6a80df6696281d7e0d2891b817d8c458fde",
            encodedString: "$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$C4TWUs9rDEvq7w3+J4umqA32aWKB1+DSiRuBfYxFj94",
            variant: .id,
            version: .latest
        )
        try hashTest(
            iterations: 2,
            memory: 16,
            threads: 1,
            password: "password",
            salt: "diffsalt",
            hexString: "bdf32b05ccc42eb15d58fd19b1f856b113da1e9a5874fdcc544308565aa8141c",
            encodedString: "$argon2id$v=19$m=65536,t=2,p=1$ZGlmZnNhbHQ$vfMrBczELrFdWP0ZsfhWsRPaHppYdP3MVEMIVlqoFBw",
            variant: .id,
            version: .latest
        )
    }

    func test_memoryTooLittle() {
        XCTAssertThrowsExpectedError(try Argon2.hash(
            iterations: 2,
            memoryInKiB: 1,
            threads: 1,
            password: "password".data(using: .utf8)!,
            salt: "diffsalt".data(using: .utf8)!,
            desiredLength: 32,
            variant: .id,
            version: .latest
        ), Argon2.Error.memoryTooLittle)
    }

    func test_saltTooShort() {
        XCTAssertThrowsExpectedError(try Argon2.hash(
            iterations: 2,
            memoryInKiB: 1 << 12,
            threads: 1,
            password: "password".data(using: .utf8)!,
            salt: "s".data(using: .utf8)!,
            desiredLength: 32,
            variant: .id,
            version: .latest
        ), Argon2.Error.saltTooShort)
    }

    private func hashTest(
        iterations: UInt32,
        memory: UInt32,
        threads: UInt32,
        password: String,
        salt: String,
        hexString: String,
        encodedString: String,
        variant: Argon2.Variant,
        version: Argon2.Version,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        let (rawOutput, encodedOutput) = try Argon2.hash(
            iterations: iterations,
            memoryInKiB: 1 << memory,
            threads: threads,
            password: password.data(using: .utf8)!,
            salt: salt.data(using: .utf8)!,
            desiredLength: 32,
            variant: variant,
            version: version
        )

        let ourHexString = rawOutput.map { String(format: "%02hhx", $0) }.joined()
        XCTAssertEqual(ourHexString, hexString, file: file, line: line)

        if version != .v10 {
            XCTAssertEqual(encodedOutput, encodedString, file: file, line: line)
        }

        XCTAssertTrue(try Argon2.verify(
            encoded: encodedOutput,
            password: password.data(using: .utf8)!,
            variant: variant
        ), file: file, line: line)

        XCTAssertTrue(try Argon2.verify(
            encoded: encodedString,
            password: password.data(using: .utf8)!,
            variant: variant
        ), file: file, line: line)
    }

    private func XCTAssertThrowsExpectedError<T, E: Error & Equatable>(
        _ expression: @autoclosure () throws -> T,
        _ expectedError: E,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), message, file: file, line: line, { error in
            XCTAssertNotNil(error as? E)
            XCTAssertEqual(error as? E, expectedError)
        })
    }
}
