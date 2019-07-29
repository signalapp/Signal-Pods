//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
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
        let keyData = Randomness.generateRandomBytes(Int32(ECCKeyLength))
        let key = try! ECPrivateKey(keyData: keyData)
        let key2 = try! ECPrivateKey(keyData: keyData)
        XCTAssertEqual(key, key2)
    }

    func testECPublicKey() {
        let keyData = Randomness.generateRandomBytes(Int32(ECCKeyLength))
        let key = try! ECPublicKey(keyData: keyData)
        XCTAssertEqual(key.keyData, keyData)

        let parsedKey = try! ECPublicKey(serializedKeyData: key.serialized)
        XCTAssertEqual(parsedKey.keyData, keyData)
        XCTAssertEqual(key, parsedKey)
    }

    func testUDMessage() {
        let keyData = Randomness.generateRandomBytes(Int32(ECCKeyLength))
        let ephemeralKey = try! ECPublicKey(keyData: keyData)
        let encryptedStatic = Randomness.generateRandomBytes(100)
        let encryptedMessage = Randomness.generateRandomBytes(200)

        let message = try! SMKUnidentifiedSenderMessage(ephemeralKey: ephemeralKey,
                                                        encryptedStatic: encryptedStatic,
                                                        encryptedMessage: encryptedMessage)

        let parsedMessage = try! SMKUnidentifiedSenderMessage(serializedData: message.serializedData)
        XCTAssertEqual(message.cipherTextVersion, parsedMessage.cipherTextVersion)
        XCTAssertEqual(message.ephemeralKey.keyData, parsedMessage.ephemeralKey.keyData)
        XCTAssertEqual(message.encryptedStatic, parsedMessage.encryptedStatic)
        XCTAssertEqual(message.encryptedMessage, parsedMessage.encryptedMessage)
    }

    func testUDServerCertificate() {
        let serializedData = try! buildServerCertificateProto().serializedData()

        let serverCertificate = try! SMKServerCertificate(serializedData: serializedData)
        let roundTripped = try! SMKServerCertificate(serializedData: serverCertificate.serializedData)

        XCTAssertEqual(serverCertificate.keyId, roundTripped.keyId)
        XCTAssertEqual(serverCertificate.key, roundTripped.key)
        XCTAssertEqual(serverCertificate.signatureData, roundTripped.signatureData)
    }

    func testUDSenderCertificate() {
        let serializedData = try! buildSenderCertificateProto().serializedData()

        let senderCertificate = try! SMKSenderCertificate(serializedData: serializedData)
        let roundTripped = try! SMKSenderCertificate(serializedData: senderCertificate.serializedData)

        XCTAssertEqual(senderCertificate.signer.serializedData, roundTripped.signer.serializedData)
        XCTAssertEqual(senderCertificate.key, roundTripped.key)
        XCTAssertEqual(senderCertificate.senderDeviceId, roundTripped.senderDeviceId)
        XCTAssertEqual(senderCertificate.senderAddress, roundTripped.senderAddress)
        XCTAssertEqual(senderCertificate.expirationTimestamp, roundTripped.expirationTimestamp)
        XCTAssertEqual(senderCertificate.signatureData, roundTripped.signatureData)
    }

    func testUDMessageContent() {
        let senderCertificateProto = buildSenderCertificateProto()
        let senderCertificate = try! SMKSenderCertificate(serializedData: try! senderCertificateProto.serializedData())

        let contentData = Randomness.generateRandomBytes(200)
        let serializedData: Data = {
            let builder =  SMKProtoUnidentifiedSenderMessageMessage.builder(senderCertificate: senderCertificateProto,
                                                                            content: contentData)
            builder.setType(.message)
            return try! builder.buildSerializedData()
        }()

        let parsed = try! SMKUnidentifiedSenderMessageContent(serializedData: serializedData)
        let message = try! SMKUnidentifiedSenderMessageContent(messageType: .whisper,
                                                              senderCertificate: senderCertificate,
                                                              contentData: contentData)

        XCTAssertEqual(message.messageType, parsed.messageType)
        XCTAssertEqual(message.senderCertificate.serializedData, parsed.senderCertificate.serializedData)
        XCTAssertEqual(message.contentData, parsed.contentData)
    }

    func testUDSessionCipher_encrypt() {
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+13213214321"), deviceId: 456, registrationId: 123)
        let bobMockClient = MockClient(address: .e164("+13213214322"), deviceId: 321, registrationId: 512)

        let certificateValidator = MockCertificateValidator()

        let bobPrekey = bobMockClient.generateMockPreKey()
        let bobSignedPrekey = bobMockClient.generateMockSignedPreKey()

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

        let plaintext = Randomness.generateRandomBytes(200)
        let paddedPlaintext = (plaintext as NSData).paddedMessageBody()!
        let senderCertificate = try! SMKSenderCertificate(serializedData: try! buildSenderCertificateProto(senderClient: aliceMockClient).serializedData())
        let encryptedMessage = try! aliceToBobCipher.throwswrapped_encryptMessage(recipientId: bobMockClient.accountId,
                                                                                  deviceId: bobMockClient.deviceId,
                                                                                  paddedPlaintext: paddedPlaintext,
                                                                                  senderCertificate: senderCertificate,
                                                                                  protocolContext: nil)

        let messageTimestamp = NSDate.ows_millisecondTimeStamp()

        let bobToAliceCipher = try! bobMockClient.createSecretSessionCipher()
        let decryptedMessage = try! bobToAliceCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                                                  cipherTextData: encryptedMessage,
                                                                                  timestamp: messageTimestamp,
                                                                                  localE164: bobMockClient.recipientE164,
                                                                                  localUuid: bobMockClient.recipientUuid,
                                                                                  localDeviceId: bobMockClient.deviceId,
                                                                                  protocolContext: nil)
        let payload = (decryptedMessage.paddedPayload as NSData).removePadding()

        XCTAssertEqual(aliceMockClient.address, decryptedMessage.senderAddress)
        XCTAssertEqual(aliceMockClient.deviceId, Int32(decryptedMessage.senderDeviceId))
        XCTAssertEqual(plaintext, payload)
    }

    // MARK: - Util

    func buildServerCertificateProto() -> SMKProtoServerCertificate {
        let serverKey = try! Curve25519.generateKeyPair().ecPublicKey().serialized
        let certificateData = try! SMKProtoServerCertificateCertificate.builder(id: 123,
                                                                                key: serverKey ).buildSerializedData()

        let signatureData = Randomness.generateRandomBytes(ECCSignatureLength)

        let wrapperProto = SMKProtoServerCertificate.builder(certificate: certificateData,
                                                             signature: signatureData)

        return try! wrapperProto.build()
    }

    func buildSenderCertificateProto(senderClient: MockClient? = nil) -> SMKProtoSenderCertificate {
        let senderAddress: SMKAddress
        let senderDevice: UInt32
        let expires = NSDate.ows_millisecondTimeStamp() + kWeekInMs
        let identityKey: ECPublicKey
        let signer = buildServerCertificateProto()

        if let senderClient = senderClient {
            senderAddress = senderClient.address
            senderDevice = UInt32(senderClient.deviceId)
            identityKey = try! senderClient.identityKeyPair.ecPublicKey()
        } else {
            senderAddress = .e164("+1235551234")
            senderDevice = 123
            identityKey = try! Curve25519.generateKeyPair().ecPublicKey()
        }

        let certificateData: Data = {
            let builder = SMKProtoSenderCertificateCertificate.builder(senderDevice: senderDevice,
                                                                       expires: expires,
                                                                       identityKey: identityKey.serialized,
                                                                       signer: signer)
            if let e164 = senderAddress.e164 {
                builder.setSenderE164(e164)
            }

            if let uuidString = senderAddress.uuid?.uuidString {
                builder.setSenderUuid(uuidString)
            }

            return try! builder.buildSerializedData()
        }()

        let signatureData = Randomness.generateRandomBytes(ECCSignatureLength)

        let wrapperProto = try! SMKProtoSenderCertificate.builder(certificate: certificateData,
                                                                  signature: signatureData).build()

        return wrapperProto
    }
}
