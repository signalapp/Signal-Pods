//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Data {
    public static func secRngGenBytes(_ count: Int) -> Data {
        Data(withFixedLengthMcMutableBufferInfallible: count) {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.pointee.buffer) == errSecSuccess
        }
    }
}
