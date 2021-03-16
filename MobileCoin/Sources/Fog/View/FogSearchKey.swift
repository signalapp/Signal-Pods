//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct FogSearchKey {
    let bytes: Data

    init(_ bytes: Data) {
        self.bytes = bytes
    }
}

extension FogSearchKey: Equatable {}
extension FogSearchKey: Hashable {}
