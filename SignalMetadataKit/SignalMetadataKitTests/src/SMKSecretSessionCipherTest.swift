//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit

// https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/SecretSessionCipherTest.java
// public class SecretSessionCipherTest extends TestCase {
class SMKSecretSessionCipherTest: XCTestCase {

    override func setUp() {
        super.setUp()
        SMKEnvironment.shared = SMKEnvironment(accountIdFinder: MockAccountIdFinder())
    }

    // public void testEncryptDecrypt() throws UntrustedIdentityException, InvalidKeyException, InvalidCertificateException, InvalidProtocolBufferException, InvalidMetadataMessageException, ProtocolDuplicateMessageException, ProtocolUntrustedIdentityException, ProtocolLegacyMessageException, ProtocolInvalidKeyException, InvalidMetadataVersionException, ProtocolInvalidVersionException, ProtocolInvalidMessageException, ProtocolInvalidKeyIdException, ProtocolNoSessionException, SelfSendException {
    func testEncryptDecrypt() {
        // TestInMemorySignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
        // TestInMemorySignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+14159999999"), deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: .e164("+14158888888"), deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient, bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()

        // SenderCertificate   senderCertificate = createCertificateFor(trustRoot, "+14151111111", 1, aliceStore.getIdentityKeyPair().getPublicKey().getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: trustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: try! aliceMockClient.identityKeyPair.ecPublicKey(),
                                                     expirationTimestamp: 31337)

        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        // senderCertificate, "smert za smert".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "smert za smert".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipientId: bobMockClient.accountId,
                                                                       deviceId: bobMockClient.deviceId,
                                                                       paddedPlaintext: alicePlaintext,
                                                                       senderCertificate: senderCertificate,
                                                                       protocolContext: nil)

        // SealedSessionCipher bobCipher = new SealedSessionCipher(bobStore, new SignalProtocolAddress("+14152222222", 1));
        let bobCipher: SMKSecretSessionCipher = try! bobMockClient.createSecretSessionCipher()

        // Pair<SignalProtocolAddress, byte[]> plaintext = bobCipher.decrypt(new CertificateValidator(trustRoot.getPublicKey()), ciphertext, 31335);
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
        let bobPlaintext = try! bobCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                                       cipherTextData: ciphertext,
                                                                       timestamp: 31335,
                                                                       localE164: bobMockClient.recipientE164,
                                                                       localUuid: bobMockClient.recipientUuid,
                                                                       localDeviceId: bobMockClient.deviceId,
                                                                       protocolContext: nil)

        // assertEquals(new String(plaintext.second()), "smert za smert");
        // assertEquals(plaintext.first().getName(), "+14151111111");
        // assertEquals(plaintext.first().getDeviceId(), 1);
        XCTAssertEqual(String(data: bobPlaintext.paddedPayload, encoding: .utf8), "smert za smert")
        XCTAssertEqual(bobPlaintext.senderAddress, aliceMockClient.address)
        XCTAssertEqual(bobPlaintext.senderDeviceId, Int(aliceMockClient.deviceId))
    }

    // public void testEncryptDecryptUntrusted() throws Exception {
    func testEncryptDecryptUntrusted() {
        // TestInMemorySignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
        // TestInMemorySignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+14159999999"), deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: .e164("+14158888888"), deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient, bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        // ECKeyPair           falseTrustRoot    = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()
        let falseTrustRoot = Curve25519.generateKeyPair()
        // SenderCertificate   senderCertificate = createCertificateFor(falseTrustRoot, "+14151111111", 1, aliceStore.getIdentityKeyPair().getPublicKey().getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: falseTrustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: try! aliceMockClient.identityKeyPair.ecPublicKey(),
                                                     expirationTimestamp: 31337)

        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        // senderCertificate, "и вот я".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "и вот я".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipientId: bobMockClient.accountId,
                                                                       deviceId: bobMockClient.deviceId,
                                                                       paddedPlaintext: alicePlaintext,
                                                                       senderCertificate: senderCertificate,
                                                                       protocolContext: nil)

        // SecretSessionCipher bobCipher = new SecretSessionCipher(bobStore);
        let bobCipher: SMKSecretSessionCipher = try! bobMockClient.createSecretSessionCipher()

        // try {
        //   bobCipher.decrypt(new CertificateValidator(trustRoot.getPublicKey()), ciphertext, 31335);
        //   throw new AssertionError();
        // } catch (InvalidMetadataMessageException e) {
        //   // good
        // }
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
        do {
            _ = try bobCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                           cipherTextData: ciphertext,
                                                           timestamp: 31335,
                                                           localE164: bobMockClient.recipientE164,
                                                           localUuid: bobMockClient.recipientUuid,
                                                           localDeviceId: bobMockClient.deviceId,
                                                           protocolContext: nil)
            XCTFail("Decryption should have failed.")
        } catch let knownSenderError as SecretSessionKnownSenderError {
            // Decryption is expected to fail.
            XCTAssert(knownSenderError.underlyingError is SMKCertificateError )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // public void testEncryptDecryptExpired() throws Exception {
    func testEncryptDecryptExpired() {
        // TestInMemorySignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
        // TestInMemorySignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+14159999999"), deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: .e164("+14158888888"), deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient, bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()

        // SenderCertificate   senderCertificate = createCertificateFor(trustRoot, "+14151111111", 1, aliceStore.getIdentityKeyPair().getPublicKey().getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: trustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: try! aliceMockClient.identityKeyPair.ecPublicKey(),
                                                     expirationTimestamp: 31337)

        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        //     senderCertificate, "и вот я".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "и вот я".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipientId: bobMockClient.accountId,
                                                                       deviceId: bobMockClient.deviceId,
                                                                       paddedPlaintext: alicePlaintext,
                                                                       senderCertificate: senderCertificate,
                                                                       protocolContext: nil)

        // SecretSessionCipher bobCipher = new SecretSessionCipher(bobStore);
        let bobCipher: SMKSecretSessionCipher = try! bobMockClient.createSecretSessionCipher()

        // try {
        //   bobCipher.decrypt(new CertificateValidator(trustRoot.getPublicKey()), ciphertext, 31338);
        //   throw new AssertionError();
        // } catch (InvalidMetadataMessageException e) {
        //   // good
        // }
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
        do {
            _ = try bobCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                           cipherTextData: ciphertext,
                                                           timestamp: 31338,
                                                           localE164: bobMockClient.recipientE164,
                                                           localUuid: bobMockClient.recipientUuid,
                                                           localDeviceId: bobMockClient.deviceId,
                                                           protocolContext: nil)
            XCTFail("Decryption should have failed.")
        } catch let knownSenderError as SecretSessionKnownSenderError {
            // Decryption is expected to fail.
            XCTAssert(knownSenderError.underlyingError is SMKCertificateError )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

     // public void testEncryptFromWrongIdentity() throws Exception {
     func testEncryptFromWrongIdentity() {
        // TestInMemorySignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
        // TestInMemorySignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: .e164("+14159999999"), deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: .e164("+14158888888"), deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient,
                           bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()
        // ECKeyPair           randomKeyPair     = Curve.generateKeyPair();
        let randomKeyPair = Curve25519.generateKeyPair()
        // SenderCertificate   senderCertificate = createCertificateFor(trustRoot, "+14151111111", 1, randomKeyPair.getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: trustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: try! randomKeyPair.ecPublicKey(),
                                                     expirationTimestamp: 31337)
        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        //    senderCertificate, "smert za smert".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "smert za smert".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipientId: bobMockClient.accountId,
                                                                       deviceId: bobMockClient.deviceId,
                                                                       paddedPlaintext: alicePlaintext,
                                                                       senderCertificate: senderCertificate,
                                                                       protocolContext: nil)

        // SecretSessionCipher bobCipher = new SecretSessionCipher(bobStore);
        let bobCipher: SMKSecretSessionCipher = try! bobMockClient.createSecretSessionCipher()

        // try {
        //   bobCipher.decrypt(new CertificateValidator(trustRoot.getPublicKey()), ciphertext, 31335);
        // } catch (InvalidMetadataMessageException e) {
        //   // good
        // }
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
        do {
            _ = try bobCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                           cipherTextData: ciphertext,
                                                           timestamp: 31335,
                                                           localE164: bobMockClient.recipientE164,
                                                           localUuid: bobMockClient.recipientUuid,
                                                           localDeviceId: bobMockClient.deviceId,
                                                           protocolContext: nil)
            XCTFail("Decryption should have failed.")
        } catch let knownSenderError as SecretSessionKnownSenderError {
            // Decryption is expected to fail.
            guard case SMKError.assertionError = knownSenderError.underlyingError else {
                XCTFail("unexpected error: \(knownSenderError.underlyingError)")
                return
            }
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

     // MARK: - Utils

    // private SenderCertificate createCertificateFor(ECKeyPair trustRoot, String sender, int deviceId, ECPublicKey identityKey, long expires)
    //     throws InvalidKeyException, InvalidCertificateException, InvalidProtocolBufferException {
    private func createCertificateFor(trustRoot: ECKeyPair,
                                      senderAddress: SMKAddress,
                                      senderDeviceId: UInt32,
                                      identityKey: ECPublicKey,
                                      expirationTimestamp: UInt64) -> SMKSenderCertificate {
        // ECKeyPair serverKey = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()

        // byte[] serverCertificateBytes = SignalProtos.ServerCertificate.Certificate.newBuilder()
        //     .setId(1)
        //     .setKey(ByteString.copyFrom(serverKey.getPublicKey().serialize()))
        //     .build()
        //     .toByteArray();
        let serverCertificateBuilder = SMKProtoServerCertificateCertificate.builder(id: 1,
                                                                                    key: try! serverKey.ecPublicKey().serialized)
        let serverCertificateData = try! serverCertificateBuilder.build().serializedData()

        // byte[] serverCertificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), serverCertificateBytes);
        let serverCertificateSignature = try! Ed25519.sign(serverCertificateData, with: trustRoot)

        // ServerCertificate serverCertificate = new ServerCertificate(SignalProtos.ServerCertificate.newBuilder()
        //     .setCertificate(ByteString.copyFrom(serverCertificateBytes))
        //     .setSignature(ByteString.copyFrom(serverCertificateSignature))
        //     .build()
        //     .toByteArray());
        let serverCertificate: SMKServerCertificate = {
            let builder = SMKProtoServerCertificate.builder(certificate: serverCertificateData,
                                                            signature: serverCertificateSignature)

            return try! SMKServerCertificate(serializedData: try! builder.buildSerializedData())
        }()

        // byte[] senderCertificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
        //     .setSender(sender)
        //     .setSenderDevice(deviceId)
        //     .setIdentityKey(ByteString.copyFrom(identityKey.serialize()))
        //     .setExpires(expires)
        //     .setSigner(SignalProtos.ServerCertificate.parseFrom(serverCertificate.getSerialized()))
        //     .build()
        //     .toByteArray();
        let senderCertificateData: Data = {
            let signer = try! SMKProtoServerCertificate.parseData(serverCertificate.serializedData)
            let builder = SMKProtoSenderCertificateCertificate.builder(senderDevice: senderDeviceId,
                                                                       expires: expirationTimestamp,
                                                                       identityKey: identityKey.serialized,
                                                                       signer: signer)
            if let e164 = senderAddress.e164 {
                builder.setSenderE164(e164)
            }

            if let uuid = senderAddress.uuid {
                builder.setSenderUuid(uuid.uuidString)
            }

            return try! builder.buildSerializedData()
        }()

        // byte[] senderCertificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), senderCertificateBytes);
        let senderCertificateSignature = try! Ed25519.sign(senderCertificateData, with: serverKey)

        // return new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
        //     .setCertificate(ByteString.copyFrom(senderCertificateBytes))
        //     .setSignature(ByteString.copyFrom(senderCertificateSignature))
        //     .build()
        //     .toByteArray());
        return {
            let builder = SMKProtoSenderCertificate.builder(certificate: senderCertificateData,
                                                            signature: senderCertificateSignature)
            return try! SMKSenderCertificate(serializedData: try! builder.buildSerializedData())
        }()
    }

    // private void initializeSessions(TestInMemorySignalProtocolStore aliceStore, TestInMemorySignalProtocolStore bobStore)
    //     throws InvalidKeyException, UntrustedIdentityException
    private func initializeSessions(aliceMockClient: MockClient, bobMockClient: MockClient) {
        // ECKeyPair          bobPreKey       = Curve.generateKeyPair();
        let bobPreKey = bobMockClient.generateMockPreKey()

        // IdentityKeyPair    bobIdentityKey  = bobStore.getIdentityKeyPair();
        let bobIdentityKey = bobMockClient.identityKeyPair

        // SignedPreKeyRecord bobSignedPreKey = KeyHelper.generateSignedPreKey(bobIdentityKey, 2);
        let bobSignedPreKey = bobMockClient.generateMockSignedPreKey()

        // PreKeyBundle bobBundle             = new PreKeyBundle(1, 1, 1, bobPreKey.getPublicKey(), 2, bobSignedPreKey.getKeyPair().getPublicKey(), bobSignedPreKey.getSignature(), bobIdentityKey.getPublicKey());
        let bobBundle = PreKeyBundle(registrationId: bobMockClient.registrationId,
                                     deviceId: bobMockClient.deviceId,
                                     preKeyId: bobPreKey.id,
                                     preKeyPublic: try! bobPreKey.keyPair.ecPublicKey().serialized,
                                     signedPreKeyPublic: try! bobSignedPreKey.keyPair.ecPublicKey().keyData.prependKeyType(),
                                     signedPreKeyId: bobSignedPreKey.id,
                                     signedPreKeySignature: bobSignedPreKey.signature,
                                     identityKey: try! bobIdentityKey.ecPublicKey().keyData.prependKeyType())!

        // SessionBuilder aliceSessionBuilder = new SessionBuilder(aliceStore, new SignalProtocolAddress("+14152222222", 1));
        let aliceSessionBuilder = aliceMockClient.createSessionBuilder(forRecipient: bobMockClient)

        // aliceSessionBuilder.process(bobBundle);
        try! aliceSessionBuilder.processPrekeyBundle(bobBundle, protocolContext: nil)

        // bobStore.storeSignedPreKey(2, bobSignedPreKey);
        // bobStore.storePreKey(1, new PreKeyRecord(1, bobPreKey));
        // NOTE: These stores are taken care of in the mocks' createKey() methods above.
    }
}
