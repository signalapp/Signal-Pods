//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public typealias BlockVersion = UInt32

extension BlockVersion {
    static let versionZero: BlockVersion = 0
    static let versionOne: BlockVersion = 1
    static let versionTwo: BlockVersion = 2
    static let versionThree: BlockVersion = 2
    static let versionMax: BlockVersion = UInt32.max

    static func canEnableRecoverableMemos(version: BlockVersion) -> Bool {
        version >= versionOne
    }

    static var legacy: BlockVersion {
        Self.versionZero
    }

    static var minRTHEnabled: BlockVersion {
        Self.versionOne
    }
}
