//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalCoreKit

// See:
// https://github.com/signalapp/libsignal-protocol-java/blob/87fae0f98332e98a32bbb82515428b4edeb4181f/java/src/main/java/org/whispersystems/libsignal/ecc/ECPrivateKey.java
@objc public class ECPrivateKey: NSObject {

    @objc
    public let keyData: Data

    @objc
    public init(keyData: Data) throws {
        guard keyData.count == ECCKeyLength else {
            throw OWSAssertionError("\(ECPrivateKey.logTag) key has invalid length")
        }

        self.keyData = keyData
    }

    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? ECPrivateKey {
            return keyData == object.keyData
        } else {
            return false
        }
    }

    public override var hash: Int {
        return keyData.hashValue
    }
}
