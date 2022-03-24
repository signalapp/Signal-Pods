//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalCoreKit
import LibSignalClient

// Work around Swift's lack of factory initializers.
// See https://bugs.swift.org/browse/SR-5255.
public protocol ECKeyPairFromIdentityKeyPair {}
public extension ECKeyPairFromIdentityKeyPair {
    init(_ keyPair: IdentityKeyPair) {
        self = ECKeyPairImpl(keyPair) as! Self
    }
}
extension ECKeyPair: ECKeyPairFromIdentityKeyPair {}

// TODO: Eventually we should define ECKeyPair entirely in Swift as a wrapper around IdentityKeyPair,
// but doing that right now would break clients that are importing Curve25519.h and nothing else.
// For now, just provide the API we'd like to have in the future via its subclass.
extension ECKeyPair {
    public var identityKeyPair: IdentityKeyPair {
        (self as! ECKeyPairImpl).storedKeyPair
    }

    // TODO: Rename to publicKey(), rename existing publicKey() method to publicKeyData().
    public func ecPublicKey() throws -> ECPublicKey {
        return ECPublicKey(self.identityKeyPair.publicKey)
    }

    // TODO: Rename to privateKey(), rename existing privateKey() method to privateKeyData().
    public func ecPrivateKey() throws -> ECPrivateKey {
        return ECPrivateKey(self.identityKeyPair.privateKey)
    }

    @objc private class var concreteSubclass: ECKeyPair.Type {
        return ECKeyPairImpl.self
    }
}

/// A transitionary class. Do not use directly; continue using ECKeyPair instead.
private class ECKeyPairImpl: ECKeyPair {
    private static let TSECKeyPairPublicKey = "TSECKeyPairPublicKey"
    private static let TSECKeyPairPrivateKey = "TSECKeyPairPrivateKey"

    let storedKeyPair: IdentityKeyPair

    init(_ keyPair: IdentityKeyPair) {
        storedKeyPair = keyPair
        super.init(fromClassClusterSubclassOnly: ())
    }

    override convenience init(publicKeyData: Data, privateKeyData: Data) throws {
        // Go through ECPublicKey to handle the public key data without a type byte.
        let publicKey = try ECPublicKey(keyData: publicKeyData).key
        let privateKey = try PrivateKey(privateKeyData)

        self.init(IdentityKeyPair(publicKey: publicKey, privateKey: privateKey))
    }

    required convenience init?(coder: NSCoder) {
        var returnedLength = 0

        let publicKeyBuffer = coder.decodeBytes(forKey: Self.TSECKeyPairPublicKey, returnedLength: &returnedLength)
        guard returnedLength == ECCKeyLength else {
            owsFailDebug("failure: wrong length for public key.")
            return nil
        }
        let publicKeyData = Data(bytes: publicKeyBuffer!, count: returnedLength)

        let privateKeyBuffer = coder.decodeBytes(forKey: Self.TSECKeyPairPrivateKey, returnedLength: &returnedLength)
        guard returnedLength == ECCKeyLength else {
            owsFailDebug("failure: wrong length for private key.")
            return nil
        }
        let privateKeyData = Data(bytes: privateKeyBuffer!, count: returnedLength)

        do {
            try self.init(publicKeyData: publicKeyData, privateKeyData: privateKeyData)
        } catch {
            owsFailDebug("error: \(error)")
            return nil
        }
    }

    override func encode(with coder: NSCoder) {
        // Go through ECPublicKey to drop the type byte.
        self.identityKeyPair.publicKey.keyBytes.withUnsafeBufferPointer {
            coder.encodeBytes($0.baseAddress, length: $0.count, forKey: Self.TSECKeyPairPublicKey)
        }
        self.identityKeyPair.privateKey.serialize().withUnsafeBufferPointer {
            coder.encodeBytes($0.baseAddress, length: $0.count, forKey: Self.TSECKeyPairPrivateKey)
        }
    }

    override class var supportsSecureCoding: Bool {
        return true
    }

    override var classForCoder: AnyClass {
        return ECKeyPair.self
    }

    @objc private class func generateKeyPair() -> ECKeyPair {
        return ECKeyPairImpl(IdentityKeyPair.generate())
    }

    @objc private func sign(_ data: Data) throws -> Data {
        return Data(identityKeyPair.privateKey.generateSignature(message: data))
    }

    override var publicKey: Data {
        return Data(identityKeyPair.publicKey.keyBytes)
    }

    override var privateKey: Data {
        return Data(identityKeyPair.privateKey.serialize())
    }
}
