//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Dictionary {
    init<S: Sequence, V>(groupingPairs keysAndValues: S) where S.Element == (Key, V), Value == [V] {
        let keysToGroupedKeysAndValues = [Key: [(Key, V)]](grouping: keysAndValues, by: { $0.0 })
        self = keysToGroupedKeysAndValues.mapValues { groupedKeysAndValues in
            groupedKeysAndValues.map { $0.1 }
        }
    }
}
