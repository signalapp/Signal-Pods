//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit

class SMKTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testECPrivateKey() {
        let keyData = Randomness.generateRandomBytes(Int32(ECCKeyLength))!
        let key = try! ECPrivateKey(keyData: keyData)
        let key2 = try! ECPrivateKey(keyData: keyData)
        XCTAssertEqual(key, key2)
    }

    func testECPublicKey() {
        let keyData = Randomness.generateRandomBytes(Int32(ECCKeyLength))!
        let key = try! ECPublicKey(keyData: keyData)
        XCTAssertEqual(key.keyData, keyData)

        let serializedData = key.serialized
        let parsedKey = try! ECPublicKey(serializedKeyData: serializedData)
        XCTAssertEqual(parsedKey.keyData, keyData)
        XCTAssertEqual(key, parsedKey)
    }

    func testUDMessage() {
        let keyData = Randomness.generateRandomBytes(Int32(ECCKeyLength))!
        let ephemeralKey = try! ECPublicKey(keyData: keyData)
        let encryptedStatic = Randomness.generateRandomBytes(100)!
        let encryptedMessage = Randomness.generateRandomBytes(200)!

        let message = SMKUnidentifiedSenderMessage(ephemeralKey: ephemeralKey,
                                 encryptedStatic: encryptedStatic,
                                 encryptedMessage: encryptedMessage)
        let messageData = try! message.serialized()
        let parsedMessage = try! SMKUnidentifiedSenderMessage.parse(dataAndPrefix: messageData)
        XCTAssertEqual(message.cipherTextVersion, parsedMessage.cipherTextVersion)
        XCTAssertEqual(message.ephemeralKey.keyData, parsedMessage.ephemeralKey.keyData)
        XCTAssertEqual(message.encryptedStatic, parsedMessage.encryptedStatic)
        XCTAssertEqual(message.encryptedMessage, parsedMessage.encryptedMessage)
    }

    func testUDServerCertificate() {
        let keyId: UInt32 = 123
        let key = try! ECPublicKey(keyData: Randomness.generateRandomBytes(Int32(ECCKeyLength))!)
        let signatureData = Randomness.generateRandomBytes(100)!

        let serverCertificate = SMKServerCertificate(keyId: keyId,
                                                     key: key,
                                                     signatureData: signatureData)
        let serializedData = try! serverCertificate.serialized()
        let parsed = try! SMKServerCertificate.parse(data: serializedData)

        XCTAssertEqual(serverCertificate.keyId, parsed.keyId)
        XCTAssertEqual(serverCertificate.key, parsed.key)
        XCTAssertEqual(serverCertificate.signatureData, parsed.signatureData)
    }

    func testUDSenderCertificate() {
        let serverCertificate = SMKServerCertificate(keyId: 123,
                                                     key: try! ECPublicKey(keyData: Randomness.generateRandomBytes(Int32(ECCKeyLength))!),
                                                     signatureData: Randomness.generateRandomBytes(100)!)

        let key = try! ECPublicKey(keyData: Randomness.generateRandomBytes(Int32(ECCKeyLength))!)
        let senderDeviceId: UInt32 = 456
        let senderRecipientId = "+13213214321"
        let expirationTimestamp: UInt64 = 789
        let signatureData = Randomness.generateRandomBytes(100)!
        let senderCertificate = SMKSenderCertificate(signer: serverCertificate,
                                                     key: key,
                                                     senderDeviceId: senderDeviceId,
                                                     senderRecipientId: senderRecipientId,
                                                     expirationTimestamp: expirationTimestamp,
                                                     signatureData: signatureData)
        let serializedData = try! senderCertificate.serialized()
        let parsed = try! SMKSenderCertificate.parse(data: serializedData)

        XCTAssertEqual(senderCertificate.signer, parsed.signer)
        XCTAssertEqual(senderCertificate.key, parsed.key)
        XCTAssertEqual(senderCertificate.senderDeviceId, parsed.senderDeviceId)
        XCTAssertEqual(senderCertificate.senderRecipientId, parsed.senderRecipientId)
        XCTAssertEqual(senderCertificate.expirationTimestamp, parsed.expirationTimestamp)
        XCTAssertEqual(senderCertificate.signatureData, parsed.signatureData)
    }

    func testUDMessageContent() {
        let serverCertificate = SMKServerCertificate(keyId: 123,
                                                     key: try! ECPublicKey(keyData: Randomness.generateRandomBytes(Int32(ECCKeyLength))!),
                                                     signatureData: Randomness.generateRandomBytes(100)!)
        let senderCertificate = SMKSenderCertificate(signer: serverCertificate,
                                                     key: try! ECPublicKey(keyData: Randomness.generateRandomBytes(Int32(ECCKeyLength))!),
                                                     senderDeviceId: 456,
                                                     senderRecipientId: "+13213214321",
                                                     expirationTimestamp: 789,
                                                     signatureData: Randomness.generateRandomBytes(100)!)
        let contentData = Randomness.generateRandomBytes(200)!

        let message = SMKUnidentifiedSenderMessageContent(messageType: .whisper,
                                        senderCertificate: senderCertificate,
                                        contentData: contentData)
        let messageData = try! message.serialized()
        let parsed = try! SMKUnidentifiedSenderMessageContent.parse(data: messageData)

        XCTAssertEqual(message.messageType, parsed.messageType)
        XCTAssertEqual(message.senderCertificate, parsed.senderCertificate)
        XCTAssertEqual(message.contentData, parsed.contentData)
    }

    func testUDSessionCipher_encrypt() {
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(recipientId: "+13213214321", deviceId: 456, registrationId: 123)
        let bobMockClient = MockClient(recipientId: "+13213214322", deviceId: 321, registrationId: 512)

        let certificateValidator = MockCertificateValidator()

        let bobPrekey = bobMockClient.preKeyStore.createKey()
        let bobSignedPrekey = bobMockClient.signedPreKeyStore.createKey()

        let bobPreKeyBundle = PreKeyBundle(registrationId: bobMockClient.registrationId,
                                           deviceId: bobMockClient.deviceId,
                                           preKeyId: bobPrekey.id,
                                           preKeyPublic: try! bobPrekey.keyPair.ecPublicKey().serialized,
                                           signedPreKeyPublic: try! bobSignedPrekey.keyPair.ecPublicKey().serialized,
                                           signedPreKeyId: bobSignedPrekey.id,
                                           signedPreKeySignature: bobSignedPrekey.signature,
                                           identityKey: try! bobMockClient.identityKeyPair.ecPublicKey().serialized)!

        let aliceToBobSessionBuilder = aliceMockClient.createSessionBuilder(forRecipient: bobMockClient)
        try! aliceToBobSessionBuilder.processPrekeyBundle(bobPreKeyBundle, protocolContext: nil)

        let aliceToBobCipher = try! aliceMockClient.createSecretSessionCipher()

        let plaintext = Randomness.generateRandomBytes(200)!
        let paddedPlaintext = (plaintext as NSData).paddedMessageBody()!
        let serverCertificate = SMKServerCertificate(keyId: 123,
                                                     key: try! ECPublicKey(keyData: Randomness.generateRandomBytes(Int32(ECCKeyLength))!),
                                                     signatureData: Randomness.generateRandomBytes(100)!)
        let senderCertificate = SMKSenderCertificate(signer: serverCertificate,
                                                     key: try! aliceMockClient.identityKeyPair.ecPublicKey(),
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     senderRecipientId: aliceMockClient.recipientId,
                                                     expirationTimestamp: 789,
                                                     signatureData: Randomness.generateRandomBytes(100)!)
        let encryptedMessage = try! aliceToBobCipher.throwswrapped_encryptMessage(recipientId: bobMockClient.recipientId,
                                                                               deviceId: bobMockClient.deviceId,
                                                                               paddedPlaintext: paddedPlaintext, senderCertificate: senderCertificate, protocolContext: nil)

        let messageTimestamp = NSDate.ows_millisecondTimeStamp()

        let bobToAliceCipher = try! bobMockClient.createSecretSessionCipher()
        let decryptedMessage = try! bobToAliceCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                                               cipherTextData: encryptedMessage,
                                                                               timestamp: messageTimestamp,
                                                                               localRecipientId: bobMockClient.recipientId,
                                                                               localDeviceId: bobMockClient.deviceId,
                                                                               protocolContext: nil)
        let payload = (decryptedMessage.paddedPayload as NSData).removePadding()

        XCTAssertEqual(aliceMockClient.recipientId, decryptedMessage.senderRecipientId)
        XCTAssertEqual(aliceMockClient.deviceId, Int32(decryptedMessage.senderDeviceId))
        XCTAssertEqual(plaintext, payload)
    }
}
