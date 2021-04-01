//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Collection {
    func chunked(maxLength: Int) -> [SubSequence] {
        var chunks: [SubSequence] = []
        var nextIndex = startIndex
        while true {
            let startIndex = nextIndex
            _ = formIndex(&nextIndex, offsetBy: maxLength, limitedBy: endIndex)
            guard distance(from: startIndex, to: endIndex) > 0 else {
                break
            }
            chunks.append(self[startIndex ..< Swift.min(nextIndex, self.endIndex)])
        }
        return chunks
    }
}
