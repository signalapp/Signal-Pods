//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

public protocol StorageAdapter {
    func get(key: String) -> Data?
    func set(key: String, value: Data)
    func clear(key: String)
}
