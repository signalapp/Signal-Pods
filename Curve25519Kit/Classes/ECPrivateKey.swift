//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalCoreKit
import LibSignalClient

// See:
// https://github.com/signalapp/libsignal-protocol-java/blob/87fae0f98332e98a32bbb82515428b4edeb4181f/java/src/main/java/org/whispersystems/libsignal/ecc/ECPrivateKey.java
@objc public class ECPrivateKey: NSObject {
    public let key: PrivateKey

    @objc
    public var keyData: Data {
        Data(key.serialize())
    }

    @objc
    public init(keyData: Data) throws {
        self.key = try PrivateKey(keyData)
    }

    public init(_ key: PrivateKey) {
        self.key = key
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ECPrivateKey else {
            return false
        }
        // FIXME: compare private keys directly?
        return keyData == object.keyData
    }

    public override var hash: Int {
        return keyData.hashValue
    }
}
