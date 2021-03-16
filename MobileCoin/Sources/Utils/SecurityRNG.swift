//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable todo

import Security

func securityRNG(context: UnsafeMutableRawPointer?) -> UInt64 {
    var value: UInt64 = 0

    let numBytes = MemoryLayout.size(ofValue: value)
    let status = withUnsafeMutablePointer(to: &value) { valuePointer in
        SecRandomCopyBytes(kSecRandomDefault, numBytes, valuePointer)
    }

    guard status == errSecSuccess else {
        var message = ""
        if #available(iOS 11.3, *), let errorMessage = SecCopyErrorMessageString(status, nil) {
            message = ", message: \(errorMessage)"
        }
        // TODO: Handle this failure gracefully
        logger.fatalError("Failed to generate bytes. SecError: \(status)" + message)
    }

    return value
}
