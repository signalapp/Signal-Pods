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

class MockClient: NSObject {

    let recipientId: String
    let deviceId: Int32
    let registrationId: Int32

    let identityKeyPair: ECKeyPair

    let sessionStore: SPKMockProtocolStore
    let preKeyStore: SPKMockProtocolStore
    let signedPreKeyStore: SPKMockProtocolStore
    let identityStore: SPKMockProtocolStore

    init(recipientId: String, deviceId: Int32, registrationId: Int32) {
        self.recipientId = recipientId
        self.deviceId = deviceId
        self.registrationId = registrationId
        self.identityKeyPair = Curve25519.generateKeyPair()

        let protocolStore = SPKMockProtocolStore(identityKeyPair: identityKeyPair, localRegistrationId: registrationId)

        sessionStore = protocolStore
        preKeyStore = protocolStore
        signedPreKeyStore = protocolStore
        identityStore = protocolStore
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

    func generateMockPreKey() -> PreKeyRecord {
        let preKeyId: Int32 = Int32(arc4random_uniform(UInt32(INT32_MAX)))
        let keyPair = Curve25519.generateKeyPair()
        let preKey = PreKeyRecord(id: preKeyId, keyPair: keyPair)!
        self.preKeyStore.storePreKey(preKeyId, preKeyRecord: preKey)
        return preKey
    }

    func generateMockSignedPreKey() -> SignedPreKeyRecord {
        let signedPreKeyId: Int32 = Int32(arc4random_uniform(UInt32(INT32_MAX)))
        let keyPair = Curve25519.generateKeyPair()
        let generatedAt = Date()
        let identityKeyPair = self.identityStore.identityKeyPair(nil)!
        let signature = try! Ed25519.sign((keyPair.publicKey as NSData).prependKeyType() as Data, with: identityKeyPair)
        let signedPreKey = SignedPreKeyRecord(id: signedPreKeyId, keyPair: keyPair, signature: signature, generatedAt: generatedAt)!
        self.signedPreKeyStore.storeSignedPreKey(signedPreKeyId, signedPreKeyRecord: signedPreKey)
        return signedPreKey
    }
}
