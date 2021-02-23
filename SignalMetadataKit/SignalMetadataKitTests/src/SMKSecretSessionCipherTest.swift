//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit
import SignalClient
import Curve25519Kit

// https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/SecretSessionCipherTest.java
// public class SecretSessionCipherTest extends TestCase {
class SMKSecretSessionCipherTest: XCTestCase {

    // public void testEncryptDecrypt() throws UntrustedIdentityException, InvalidKeyException, InvalidCertificateException, InvalidProtocolBufferException, InvalidMetadataMessageException, ProtocolDuplicateMessageException, ProtocolUntrustedIdentityException, ProtocolLegacyMessageException, ProtocolInvalidKeyException, InvalidMetadataVersionException, ProtocolInvalidVersionException, ProtocolInvalidMessageException, ProtocolInvalidKeyIdException, ProtocolNoSessionException, SelfSendException {
    func testEncryptDecrypt() {
        // TestInMemorySignalProtocolStore aliceStore = new TestInMemorySignalProtocolStore();
        // TestInMemorySignalProtocolStore bobStore   = new TestInMemorySignalProtocolStore();
        // NOTE: We use MockClient to ensure consistency between of our session state.
        let aliceMockClient = MockClient(address: aliceAddress, deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: bobAddress, deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient, bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        let trustRoot = IdentityKeyPair.generate()

        // SenderCertificate   senderCertificate = createCertificateFor(trustRoot, "+14151111111", 1, aliceStore.getIdentityKeyPair().getPublicKey().getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: trustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: aliceMockClient.identityKeyPair.publicKey,
                                                     expirationTimestamp: 31337)

        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        // senderCertificate, "smert za smert".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "smert za smert".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipient: bobMockClient.address,
                                                                       deviceId: bobMockClient.deviceId,
                                                                       paddedPlaintext: alicePlaintext,
                                                                       senderCertificate: senderCertificate,
                                                                       protocolContext: nil)

        // SealedSessionCipher bobCipher = new SealedSessionCipher(bobStore, new SignalProtocolAddress("+14152222222", 1));
        let bobCipher: SMKSecretSessionCipher = try! bobMockClient.createSecretSessionCipher()

        // Pair<SignalProtocolAddress, byte[]> plaintext = bobCipher.decrypt(new CertificateValidator(trustRoot.getPublicKey()), ciphertext, 31335);
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: ECPublicKey(trustRoot.publicKey))
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
        let aliceMockClient = MockClient(address: aliceAddress, deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: bobAddress, deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient, bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        // ECKeyPair           falseTrustRoot    = Curve.generateKeyPair();
        let trustRoot = IdentityKeyPair.generate()
        let falseTrustRoot = IdentityKeyPair.generate()
        // SenderCertificate   senderCertificate = createCertificateFor(falseTrustRoot, "+14151111111", 1, aliceStore.getIdentityKeyPair().getPublicKey().getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: falseTrustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: aliceMockClient.identityKeyPair.publicKey,
                                                     expirationTimestamp: 31337)

        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        // senderCertificate, "и вот я".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "и вот я".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipient: bobMockClient.address,
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
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: ECPublicKey(trustRoot.publicKey))
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
        let aliceMockClient = MockClient(address: aliceAddress, deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: bobAddress, deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient, bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        let trustRoot = IdentityKeyPair.generate()

        // SenderCertificate   senderCertificate = createCertificateFor(trustRoot, "+14151111111", 1, aliceStore.getIdentityKeyPair().getPublicKey().getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: trustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: aliceMockClient.identityKeyPair.publicKey,
                                                     expirationTimestamp: 31337)

        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        //     senderCertificate, "и вот я".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "и вот я".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipient: bobMockClient.address,
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
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: ECPublicKey(trustRoot.publicKey))
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
        let aliceMockClient = MockClient(address: aliceAddress, deviceId: 1, registrationId: 1234)
        let bobMockClient = MockClient(address: bobAddress, deviceId: 1, registrationId: 1235)

        // initializeSessions(aliceStore, bobStore);
        initializeSessions(aliceMockClient: aliceMockClient,
                           bobMockClient: bobMockClient)

        // ECKeyPair           trustRoot         = Curve.generateKeyPair();
        let trustRoot = IdentityKeyPair.generate()
        // ECKeyPair           randomKeyPair     = Curve.generateKeyPair();
        let randomKeyPair = IdentityKeyPair.generate()
        // SenderCertificate   senderCertificate = createCertificateFor(trustRoot, "+14151111111", 1, randomKeyPair.getPublicKey(), 31337);
        let senderCertificate = createCertificateFor(trustRoot: trustRoot,
                                                     senderAddress: aliceMockClient.address,
                                                     senderDeviceId: UInt32(aliceMockClient.deviceId),
                                                     identityKey: randomKeyPair.publicKey,
                                                     expirationTimestamp: 31337)
        // SecretSessionCipher aliceCipher       = new SecretSessionCipher(aliceStore);
        let aliceCipher: SMKSecretSessionCipher = try! aliceMockClient.createSecretSessionCipher()

        // byte[] ciphertext = aliceCipher.encrypt(new SignalProtocolAddress("+14152222222", 1),
        //    senderCertificate, "smert za smert".getBytes());
        // NOTE: The java tests don't bother padding the plaintext.
        let alicePlaintext = "smert za smert".data(using: String.Encoding.utf8)!
        let ciphertext = try! aliceCipher.throwswrapped_encryptMessage(recipient: bobMockClient.address,
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
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: ECPublicKey(trustRoot.publicKey))
        do {
            _ = try bobCipher.throwswrapped_decryptMessage(certificateValidator: certificateValidator,
                                                           cipherTextData: ciphertext,
                                                           timestamp: 31335,
                                                           localE164: bobMockClient.recipientE164,
                                                           localUuid: bobMockClient.recipientUuid,
                                                           localDeviceId: bobMockClient.deviceId,
                                                           protocolContext: nil)
            XCTFail("Decryption should have failed.")
        } catch SignalError.invalidMessage(_) {
            // Decryption is expected to fail.
            // FIXME: This particular failure doesn't get wrapped as a SecretSessionKnownSenderError
            // because it's checked before the unwrapped message is returned.
            // Why? Because it uses crypto values calculated during unwrapping to validate the sender certificate.
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

     // MARK: - Utils

    // private SenderCertificate createCertificateFor(ECKeyPair trustRoot, String sender, int deviceId, ECPublicKey identityKey, long expires)
    //     throws InvalidKeyException, InvalidCertificateException, InvalidProtocolBufferException {
    private func createCertificateFor(trustRoot: IdentityKeyPair,
                                      senderAddress: SMKAddress,
                                      senderDeviceId: UInt32,
                                      identityKey: PublicKey,
                                      expirationTimestamp: UInt64) -> SenderCertificate {
        let serverKey = IdentityKeyPair.generate()
        let serverCertificate = try! ServerCertificate(keyId: 1,
                                                       publicKey: serverKey.publicKey,
                                                       trustRoot: trustRoot.privateKey)
        return try! SenderCertificate(sender: SealedSenderAddress(e164: senderAddress.e164,
                                                                  uuidString: senderAddress.uuid!.uuidString,
                                                                  deviceId: senderDeviceId),
                                      publicKey: identityKey,
                                      expiration: expirationTimestamp,
                                      signerCertificate: serverCertificate,
                                      signerKey: serverKey.privateKey)
    }

    // private void initializeSessions(TestInMemorySignalProtocolStore aliceStore, TestInMemorySignalProtocolStore bobStore)
    //     throws InvalidKeyException, UntrustedIdentityException
    private func initializeSessions(aliceMockClient: MockClient, bobMockClient: MockClient) {
        aliceMockClient.initializeSession(with: bobMockClient)
    }
}
