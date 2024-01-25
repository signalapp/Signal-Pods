//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

enum AttestedCallError: Error {
    case aeadError(AeadError)
    case invalidInput(String)
}

extension AttestedCallError: CustomStringConvertible {
    var description: String {
        "Attested call error: " + {
            switch self {
            case .aeadError(let innerError):
                return "\(innerError)"
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            }
        }()
    }
}
