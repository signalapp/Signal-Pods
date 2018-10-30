//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalMetadataKit

class MockCertificateValidator: NSObject, SMKCertificateValidator {

    @objc public func throwswrapped_validate(senderCertificate: SMKSenderCertificate, validationTime: UInt64) throws {
        // Do not throw
    }

    @objc public func throwswrapped_validate(serverCertificate: SMKServerCertificate) throws {
        // Do not throw
    }
}

// MARK: -

class MockIdentityStore: NSObject, IdentityKeyStore {

    private let localIdentityKeyPair: ECKeyPair?
    private let localRegistrationId: Int32
    private var identityKeyMap = [String: Data]()

    init(localIdentityKeyPair: ECKeyPair?, localRegistrationId: Int32) {
        self.localIdentityKeyPair = localIdentityKeyPair
        self.localRegistrationId = localRegistrationId
    }

    public func identityKeyPair(_ protocolContext: Any?) -> ECKeyPair? {
        return localIdentityKeyPair
    }

    public func localRegistrationId(_ protocolContext: Any?) -> Int32 {
        return localRegistrationId
    }

    // @returns YES if we are replacing an existing known identity key for recipientId.
    //          NO  if there was no previously stored identity key for the recipient.
    public func saveRemoteIdentity(_ identityKey: Data, recipientId: String, protocolContext: Any?) -> Bool {
        let didReplace = identityKeyMap[recipientId] != nil
        identityKeyMap[recipientId] = identityKey
        return didReplace
    }

    public func isTrustedIdentityKey(_ identityKey: Data, recipientId: String, direction: TSMessageDirection, protocolContext: Any?) -> Bool {
        return true
    }

    public func identityKey(forRecipientId recipientId: String) -> Data? {
        if let identityKey = identityKeyMap[recipientId] {
            return identityKey
        }
        let identityKey = Randomness.generateRandomBytes(100)!
        identityKeyMap[recipientId] = identityKey
        return identityKey
    }

    public func identityKey(forRecipientId recipientId: String, protocolContext: Any?) -> Data? {
        return identityKey(forRecipientId: recipientId)
    }
}

// MARK: -

private class MockSessionKey: NSObject {
    let contactIdentifier: String
    let deviceId: Int32

    init(contactIdentifier: String, deviceId: Int32) {
        self.contactIdentifier = contactIdentifier
        self.deviceId = deviceId
    }

    open override func isEqual(_ other: Any?) -> Bool {
        if let other = other as? MockSessionKey {
            return contactIdentifier == other.contactIdentifier && deviceId == other.deviceId
        } else {
            return false
        }
    }

    public override var hash: Int {
        return contactIdentifier.hashValue ^ deviceId.hashValue
    }
}

// MARK: -

class MockSessionStore: NSObject, SessionStore {

    private var sessionMap = [MockSessionKey: SessionRecord]()

    public func loadSession(_ contactIdentifier: String, deviceId: Int32, protocolContext: Any?) -> SessionRecord {
        let sessionKey = MockSessionKey(contactIdentifier: contactIdentifier, deviceId: deviceId)
        if let sessionRecord = sessionMap[sessionKey] {
            return sessionRecord
        }
        let sessionRecord = SessionRecord()!
        return sessionRecord
    }

    public func subDevicesSessions(_ contactIdentifier: String, protocolContext: Any?) -> [Any] {
        notImplemented()
    }

    public func storeSession(_ contactIdentifier: String, deviceId: Int32, session: SessionRecord, protocolContext: Any?) {
        let sessionKey = MockSessionKey(contactIdentifier: contactIdentifier, deviceId: deviceId)
        sessionMap[sessionKey] = session
    }

    public func containsSession(_ contactIdentifier: String, deviceId: Int32, protocolContext: Any?) -> Bool {
        return self.loadSession(contactIdentifier, deviceId: deviceId, protocolContext: protocolContext).sessionState().hasSenderChain()
    }

    public func deleteSession(forContact contactIdentifier: String, deviceId: Int32, protocolContext: Any?) {
        let sessionKey = MockSessionKey(contactIdentifier: contactIdentifier, deviceId: deviceId)
        sessionMap.removeValue(forKey: sessionKey)
    }

    public func deleteAllSessions(forContact contactIdentifier: String, protocolContext: Any?) {
        sessionMap.removeAll()
    }
}

// MARK: -

class MockPreKeyStore: NSObject, PreKeyStore {

    private var keyMap = [Int32: PreKeyRecord]()

    func createKey() -> PreKeyRecord {
        let preKeyId: Int32 = Int32(arc4random_uniform(UInt32(INT32_MAX)))
        let keyPair = Curve25519.generateKeyPair()
        let preKey = PreKeyRecord(id: preKeyId, keyPair: keyPair)!
        keyMap[preKeyId] = preKey
        return preKey
    }

    public func loadPreKey(_ preKeyId: Int32) -> PreKeyRecord {
        return keyMap[preKeyId]!
    }

    public func storePreKey(_ preKeyId: Int32, preKeyRecord record: PreKeyRecord) {
        notImplemented()
    }

    public func containsPreKey(_ preKeyId: Int32) -> Bool {
        notImplemented()
    }

    public func removePreKey(_ preKeyId: Int32) {
        notImplemented()
    }
}

// MARK: -

class MockSignedPreKeyStore: NSObject, SignedPreKeyStore {
    let identityKeyPair: ECKeyPair

    init(identityKeyPair: ECKeyPair) {
        self.identityKeyPair = identityKeyPair
    }
    private var keyMap = [Int32: SignedPreKeyRecord]()

    func createKey() -> SignedPreKeyRecord {
        let signedPreKeyId: Int32 = Int32(arc4random_uniform(UInt32(INT32_MAX)))
        let keyPair = Curve25519.generateKeyPair()
        let generatedAt = Date()
        let signature = try! Ed25519.sign((keyPair.publicKey as NSData).prependKeyType() as Data, with: identityKeyPair)
        let signedPreKey = SignedPreKeyRecord(id: signedPreKeyId, keyPair: keyPair, signature: signature, generatedAt: generatedAt)!
        keyMap[signedPreKeyId] = signedPreKey
        return signedPreKey
    }

    public func loadSignedPrekey(_ signedPreKeyId: Int32) -> SignedPreKeyRecord {
        return keyMap[signedPreKeyId]!
    }

    public func loadSignedPrekeyOrNil(_ signedPreKeyId: Int32) -> SignedPreKeyRecord? {
        notImplemented()
    }

    public func loadSignedPreKeys() -> [SignedPreKeyRecord] {
        notImplemented()
    }

    public func storeSignedPreKey(_ signedPreKeyId: Int32, signedPreKeyRecord: SignedPreKeyRecord) {
        notImplemented()
    }

    public func containsSignedPreKey(_ signedPreKeyId: Int32) -> Bool {
        notImplemented()
    }

    public func removeSignedPreKey(_ signedPrekeyId: Int32) {
        notImplemented()
    }
}

// MARK: -

class MockClient: NSObject {

    let recipientId: String
    let deviceId: Int32
    let registrationId: Int32

    let identityKeyPair: ECKeyPair

    let sessionStore: MockSessionStore
    let preKeyStore: MockPreKeyStore
    let signedPreKeyStore: MockSignedPreKeyStore
    let identityStore: MockIdentityStore

    init(recipientId: String, deviceId: Int32, registrationId: Int32) {
        self.recipientId = recipientId
        self.deviceId = deviceId
        self.registrationId = registrationId

        identityKeyPair = Curve25519.generateKeyPair()

        sessionStore = MockSessionStore()
        preKeyStore = MockPreKeyStore()
        signedPreKeyStore = MockSignedPreKeyStore(identityKeyPair: identityKeyPair)
        identityStore = MockIdentityStore(localIdentityKeyPair: identityKeyPair, localRegistrationId: registrationId)
    }

    func createSessionCipher() -> SessionCipher {
        return SessionCipher(sessionStore: sessionStore,
                             preKeyStore: preKeyStore,
                             signedPreKeyStore: signedPreKeyStore,
                             identityKeyStore: identityStore,
                             recipientId: recipientId,
                             deviceId: deviceId)
    }

    func createSecretSessionCipher() throws -> SMKSecretSessionCipher {
        return try SMKSecretSessionCipher(sessionStore: sessionStore,
                                      preKeyStore: preKeyStore,
                                      signedPreKeyStore: signedPreKeyStore,
                                      identityStore: identityStore)
    }

    func createSessionBuilder(forRecipient recipient: MockClient) -> SessionBuilder {
        return SessionBuilder(sessionStore: sessionStore,
                              preKeyStore: preKeyStore,
                              signedPreKeyStore: signedPreKeyStore,
                              identityKeyStore: identityStore,
                              recipientId: recipient.recipientId,
                              deviceId: recipient.deviceId)
    }
}
