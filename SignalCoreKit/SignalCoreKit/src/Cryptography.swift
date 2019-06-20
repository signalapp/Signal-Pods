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
}
