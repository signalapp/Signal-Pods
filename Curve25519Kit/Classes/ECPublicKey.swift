//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalCoreKit
import LibSignalClient

// See:
// https://github.com/signalapp/libsignal-protocol-java/blob/87fae0f98332e98a32bbb82515428b4edeb4181f/java/src/main/java/org/whispersystems/libsignal/ecc/DjbECPublicKey.java
@objc public class ECPublicKey: NSObject {

    @objc
    public static let keyTypeDJB: UInt8 = 0x05

    public let key: PublicKey

    @objc
    public var keyData: Data {
        return Data(key.keyBytes)
    }

    @objc
    public init(keyData: Data) throws {
        self.key = try PublicKey([ECPublicKey.keyTypeDJB] + keyData)
    }

    public init(_ key: PublicKey) {
        self.key = key
    }

    // https://github.com/signalapp/libsignal-protocol-java/blob/master/java/src/main/java/org/whispersystems/libsignal/ecc/Curve.java#L30
    @objc
    public init(serializedKeyData: Data) throws {
        self.key = try PublicKey(serializedKeyData)
    }

    @objc public var serialized: Data {
        return Data(key.serialize())
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ECPublicKey else {
            return false
        }
        return key == object.key
    }

    public override var hash: Int {
        return keyData.hashValue
    }
}
