//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Collection {
    subscript(indices: [Index]) -> [Element] {
        indices.map { self[$0] }
    }
}
