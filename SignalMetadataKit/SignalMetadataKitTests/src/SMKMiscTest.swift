//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit
import SignalCoreKit
import Curve25519Kit
import SignalClient

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

    func testUDSessionCipher_encrypt() {
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: aliceAddress, deviceId: 456, registrationId: 123)
        let bobMockClient = MockClient(address: bobAddress, deviceId: 321, registrationId: 512)

        let certificateValidator = MockCertificateValidator()

        aliceMockClient.initializeSession(with: bobMockClient)

        let aliceToBobCipher = try! aliceMockClient.createSecretSessionCipher()

        let plaintext = Randomness.generateRandomBytes(200)
        let paddedPlaintext = (plaintext as NSData).paddedMessageBody()
        let senderCertificate = try! SenderCertificate(buildSenderCertificateProto(senderClient: aliceMockClient).serializedData())
        let encryptedMessage = try! aliceToBobCipher.throwswrapped_encryptMessage(recipient: bobMockClient.address,
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
        let identityKey: IdentityKey
        let signer = buildServerCertificateProto()

        if let senderClient = senderClient {
            senderAddress = senderClient.address
            senderDevice = UInt32(senderClient.deviceId)
            identityKey = senderClient.identityKeyPair.identityKey
        } else {
            senderAddress = .e164("+1235551234")
            senderDevice = 123
            identityKey = IdentityKeyPair.generate().identityKey
        }

        let certificateData: Data = {
            let builder = SMKProtoSenderCertificateCertificate.builder(senderDevice: senderDevice,
                                                                       expires: expires,
                                                                       identityKey: Data(identityKey.serialize()),
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
