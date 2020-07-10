//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import CommonCrypto

public extension Cryptography {
    class func pbkdf2Derivation(password: Data, salt: Data, iterations: UInt32, outputLength: Int) -> Data? {
        guard password.count > 0 else {
            owsFailDebug("Invalid password.")
            return nil
        }

        guard salt.count > 0 else {
            owsFailDebug("Invalid salt.")
            return nil
        }

        guard iterations > 0 else {
            owsFailDebug("Invalid iterations.")
            return nil
        }

        guard outputLength > 0 else {
            owsFailDebug("Invalid outputLength.")
            return nil
        }

        let passwordBytes: [Int8] = password.withUnsafeBytes {
            [Int8]($0.bindMemory(to: Int8.self))
        }
        let saltBytes: [UInt8] = salt.withUnsafeBytes { [UInt8]($0) }
        var outputBytes = [UInt8](repeating: 0, count: outputLength)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes,
            passwordBytes.count,
            saltBytes,
            saltBytes.count,
            CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
            iterations,
            &outputBytes,
            outputBytes.count
        )

        guard status == noErr else {
            owsFailDebug("Unexpected status: \(status)")
            return nil
        }

        return Data(outputBytes)
    }

    // MARK: - HMAC-SIV

    private static let hmacsivIVLength = 16
    private static let hmacsivDataLength = 32

    private class func invalidLengthError(_ parameter: String) -> Error {
        return OWSAssertionError("\(parameter) length is invalid")
    }

    /// Encrypts a 32-byte `data` with the provided 32-byte `key` using SHA-256 HMAC-SIV.
    /// Returns a tuple of (16-byte IV, 32-byte Ciphertext) or `nil` if an error occurs.
    class func encryptSHA256HMACSIV(data: Data, key: Data) throws -> (iv: Data, ciphertext: Data) {
        guard data.count == hmacsivDataLength else { throw invalidLengthError("data") }
        guard key.count == hmacsivDataLength else { throw invalidLengthError("key") }

        guard let authData = "auth".data(using: .utf8),
            let Ka = computeSHA256HMAC(authData, withHMACKey: key) else {
                throw OWSAssertionError("failed to compute Ka")
        }
        guard let encData = "enc".data(using: .utf8),
            let Ke = computeSHA256HMAC(encData, withHMACKey: key) else {
                throw OWSAssertionError("failed to compute Ke")
        }

        guard let iv = truncatedSHA256HMAC(data, withHMACKey: Ka, truncation: UInt(hmacsivIVLength)) else {
            throw OWSAssertionError("failed to compute IV")
        }

        guard let Kx = computeSHA256HMAC(iv, withHMACKey: Ke) else {
            throw OWSAssertionError("failed to compute Kx")
        }

        let ciphertext = try Kx ^ data

        return (iv, ciphertext)
    }

    /// Decrypts a 32-byte `cipherText` with the provided 32-byte `key` and 16-byte `iv` using SHA-256 HMAC-SIV.
    /// Returns the decrypted 32-bytes of data or `nil` if an error occurs.
    class func decryptSHA256HMACSIV(iv: Data, cipherText: Data, key: Data) throws -> Data {
        guard iv.count == hmacsivIVLength else { throw invalidLengthError("iv") }
        guard cipherText.count == hmacsivDataLength else { throw invalidLengthError("cipherText") }
        guard key.count == hmacsivDataLength else { throw invalidLengthError("key") }

        guard let authData = "auth".data(using: .utf8),
            let Ka = computeSHA256HMAC(authData, withHMACKey: key) else {
                throw OWSAssertionError("failed to compute Ka")
        }
        guard let encData = "enc".data(using: .utf8),
            let Ke = computeSHA256HMAC(encData, withHMACKey: key) else {
                throw OWSAssertionError("failed to compute Ke")
        }

        guard let Kx = computeSHA256HMAC(iv, withHMACKey: Ke) else {
            throw OWSAssertionError("failed to compute Kx")
        }

        let decryptedData = try Kx ^ cipherText

        guard let ourIV = truncatedSHA256HMAC(decryptedData, withHMACKey: Ka, truncation: UInt(hmacsivIVLength)) else {
            throw OWSAssertionError("failed to compute IV")
        }

        guard ourIV.ows_constantTimeIsEqual(to: iv) else {
            throw OWSAssertionError("failed to validate IV")
        }

        return decryptedData
    }

    // SHA-256

    /// Generates the SHA256 digest for a file.
    class func computeSHA256DigestOfFile(at url: URL) -> Data? {
        let bufferSize = 1024 * 1024

        let file: FileHandle

        do {
            file = try FileHandle(forReadingFrom: url)
        } catch {
            owsFailDebug("Cannot open file: \(error.localizedDescription)")
            return nil
        }

        defer { file.closeFile() }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context
        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_SHA256_Update(&context, $0.baseAddress, numericCast(data.count))
                }
                return true // Continue
            } else {
                return false // End of file
            }
        }) { }

        // Compute the SHA256 digest
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = CC_SHA256_Final(&digest, &context)

        return Data(digest)
    }
}

extension Data {
    static func ^(lhs: Data, rhs: Data) throws -> Data {
        guard lhs.count == rhs.count else { throw OWSAssertionError("lhs length must equal rhs length") }
        return Data(zip(lhs, rhs).map { $0 ^ $1 })
    }
}
