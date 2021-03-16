//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol InfiniteIteratorProtocol {
    associatedtype Element

    mutating func next() -> Self.Element
}
