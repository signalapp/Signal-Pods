//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Dictionary {
    subscript(keys: [Key]) -> [Value]? {
        let compacted = keys.compactMap { self[$0] }
        guard compacted.count == keys.count else {
            return nil
        }
        return compacted
    }
}
