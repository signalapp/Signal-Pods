//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension DataConvertible {
    func hexEncodedString() -> String {
        reduce(into: "") { accum, byte in
            accum.append(String(byte, radix: 16))
        }
    }
}
