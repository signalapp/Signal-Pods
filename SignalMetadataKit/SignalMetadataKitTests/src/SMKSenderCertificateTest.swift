//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit

// See: https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/certificate/SenderCertificateTest.java
//
//public class SenderCertificateTest extends TestCase {
class SMKSenderCertificateTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //    private final ECKeyPair trustRoot = Curve.generateKeyPair();
    let trustRoot = Curve25519.generateKeyPair()

    //    public void testSignature() throws InvalidCertificateException, InvalidKeyException {
    func testSignature() {
        //        ECKeyPair serverKey = Curve.generateKeyPair();
        //        ECKeyPair key       = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()
        let key       = Curve25519.generateKeyPair()

        //        byte[] certificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
        //            .setSender("+14152222222")
        //            .setSenderDevice(1)
        //            .setExpires(31337)
        //            .setIdentityKey(ByteString.copyFrom(key.getPublicKey().serialize()))
        //            .setSigner(getServerCertificate(serverKey))
        //            .build()
        //            .toByteArray();

        let senderRecipientId = "+14152222222"
        let senderDeviceId: UInt32 = 1
        let expirationTimestamp: UInt64 = 31337

        let serverCertificate = getServerCertificate(serverKey: serverKey, trustRoot: trustRoot)
        let unsignedCertificateBuilder = SMKProtoSenderCertificateCertificate.builder(sender: senderRecipientId,
                                                                                      senderDevice: senderDeviceId,
                                                                                      expires: expirationTimestamp,
                                                                                      identityKey: try! key.ecPublicKey().serialized,
                                                                                      signer: try! serverCertificate.toProto())
        unsignedCertificateBuilder.setSigner(try! serverCertificate.toProto())
        let unsignedSenderCertificateData = try! unsignedCertificateBuilder.build().serializedData()

        //        byte[] certificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), certificateBytes);
        let senderCertificateSignature = try! Ed25519.sign(unsignedSenderCertificateData, with: serverKey)

        //        SenderCertificate senderCertificate  = new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
        //            .setCertificate(ByteString.copyFrom(certificateBytes))
        //            .setSignature(ByteString.copyFrom(certificateSignature))
        //            .build()
        //            .toByteArray());
        let signedSenderCertificate = SMKSenderCertificate(signer: serverCertificate,
                                                           key: try! key.ecPublicKey(),
                                                           senderDeviceId: senderDeviceId,
                                                           senderRecipientId: senderRecipientId,
                                                           expirationTimestamp: expirationTimestamp,
                                                           signatureData: senderCertificateSignature)

        //        new CertificateValidator(trustRoot.getPublicKey()).validate(senderCertificate, 31336);
        let certificateValidator = try! SMKCertificateDefaultValidator(trustRoot: trustRoot.ecPublicKey())
        try! certificateValidator.throwswrapped_validate(senderCertificate: signedSenderCertificate, validationTime: 31336)
    }

    //    public void testExpiredSignature() throws InvalidCertificateException, InvalidKeyException {
    func testExpiredSignature() {
        //        ECKeyPair serverKey = Curve.generateKeyPair();
        //        ECKeyPair key       = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()
        let key       = Curve25519.generateKeyPair()

        //        byte[] certificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
        //            .setSender("+14152222222")
        //            .setSenderDevice(1)
        //            .setExpires(31337)
        //            .setIdentityKey(ByteString.copyFrom(key.getPublicKey().serialize()))
        //            .setSigner(getServerCertificate(serverKey))
        //            .build()
        //            .toByteArray();
        let senderRecipientId = "+14152222222"
        let senderDeviceId: UInt32 = 1
        let expirationTimestamp: UInt64 = 31337

        let serverCertificate = getServerCertificate(serverKey: serverKey, trustRoot: trustRoot)
        let unsignedCertificateBuilder = SMKProtoSenderCertificateCertificate.builder(sender: senderRecipientId,
                                                                                      senderDevice: senderDeviceId,
                                                                                      expires: expirationTimestamp,
                                                                                      identityKey: try! key.ecPublicKey().serialized,
                                                                                      signer: try! serverCertificate.toProto())
        let unsignedSenderCertificateData = try! unsignedCertificateBuilder.build().serializedData()

        //        byte[] certificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), certificateBytes);
        let senderCertificateSignature = try! Ed25519.sign(unsignedSenderCertificateData, with: serverKey)

        //        SenderCertificate senderCertificate  = new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
        //            .setCertificate(ByteString.copyFrom(certificateBytes))
        //            .setSignature(ByteString.copyFrom(certificateSignature))
        //            .build()
        //            .toByteArray());
        let signedSenderCertificate = SMKSenderCertificate(signer: serverCertificate,
                                                           key: try! key.ecPublicKey(),
                                                           senderDeviceId: senderDeviceId,
                                                           senderRecipientId: senderRecipientId,
                                                           expirationTimestamp: expirationTimestamp,
                                                           signatureData: senderCertificateSignature)

        //        try {
        //        new CertificateValidator(trustRoot.getPublicKey()).validate(senderCertificate, 31338);
        //        throw new AssertionError();
        //        } catch (InvalidCertificateException e) {
        //        // good
        //        }
        let certificateValidator = try! SMKCertificateDefaultValidator(trustRoot: trustRoot.ecPublicKey())
        XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(senderCertificate: signedSenderCertificate, validationTime: 31338))
    }

    //    public void testBadSignature() throws InvalidCertificateException, InvalidKeyException {
    func testBadSignature() {
    //        ECKeyPair serverKey = Curve.generateKeyPair();
    //        ECKeyPair key       = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()
        let key       = Curve25519.generateKeyPair()

    //        byte[] certificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
    //            .setSender("+14152222222")
    //            .setSenderDevice(1)
    //            .setExpires(31337)
    //            .setIdentityKey(ByteString.copyFrom(key.getPublicKey().serialize()))
    //            .setSigner(getServerCertificate(serverKey))
    //            .build()
    //            .toByteArray();
        let senderRecipientId = "+14152222222"
        let senderDeviceId: UInt32 = 1
        let expirationTimestamp: UInt64 = 31337

        let serverCertificate = getServerCertificate(serverKey: serverKey, trustRoot: trustRoot)
        let unsignedCertificateBuilder = SMKProtoSenderCertificateCertificate.builder(sender: senderRecipientId,
                                                                                      senderDevice: senderDeviceId,
                                                                                      expires: expirationTimestamp,
                                                                                      identityKey: try! key.ecPublicKey().serialized,
                                                                                      signer: try! serverCertificate.toProto())
        let unsignedSenderCertificateData = try! unsignedCertificateBuilder.build().serializedData()

    //        byte[] certificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), certificateBytes);
        let senderCertificateSignature = try! Ed25519.sign(unsignedSenderCertificateData, with: serverKey)

    //        for (int i=0;i<certificateSignature.length;i++) {
        for i in 0..<senderCertificateSignature.count {
    //            for (int b=0;b<8;b++) {
            for b in 0..<8 {
    //                byte[] badSignature = new byte[certificateSignature.length];
    //                System.arraycopy(certificateSignature, 0, badSignature, 0, certificateSignature.length);
                var badSignature = senderCertificateSignature

    //                badSignature[i] = (byte)(badSignature[i] ^ 1 << b);
                badSignature.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
                    bytes[i] = (UInt8)(bytes[i] ^ 1 << b)
                }

    //                SenderCertificate senderCertificate = new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
    //                    .setCertificate(ByteString.copyFrom(certificateBytes))
    //                    .setSignature(ByteString.copyFrom(badSignature))
    //                    .build()
    //                    .toByteArray());
                let signedSenderCertificate = SMKSenderCertificate(signer: serverCertificate,
                                                                   key: try! key.ecPublicKey(),
                                                                   senderDeviceId: senderDeviceId,
                                                                   senderRecipientId: senderRecipientId,
                                                                   expirationTimestamp: expirationTimestamp,
                                                                   signatureData: badSignature)

    //                try {
    //                new CertificateValidator(trustRoot.getPublicKey()).validate(senderCertificate, 31336);
    //                throw new AssertionError();
    //                } catch (InvalidCertificateException e) {
    //                // good
    //                }
                let certificateValidator = try! SMKCertificateDefaultValidator(trustRoot: trustRoot.ecPublicKey())
                XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(senderCertificate: signedSenderCertificate, validationTime: 31336))
            }
        }
    }

    // MARK: - Utils

    //    private SignalProtos.ServerCertificate getServerCertificate(ECKeyPair serverKey) throws InvalidKeyException, InvalidCertificateException {
    private func getServerCertificate(serverKey: ECKeyPair, trustRoot: ECKeyPair) -> SMKServerCertificate {
        //        byte[] certificateBytes = SignalProtos.ServerCertificate.Certificate.newBuilder()
        //            .setId(1)
        //            .setKey(ByteString.copyFrom(serverKey.getPublicKey().serialize()))
        //            .build()
        //            .toByteArray();
        let keyId: UInt32 = 1
        let unsignedServerCertificateBuilder = SMKProtoServerCertificateCertificate.builder(id: keyId,
                                                                                            key: try! serverKey.ecPublicKey().serialized)
        let unsignedServerCertificateData = try! unsignedServerCertificateBuilder.build().serializedData()

        //        byte[] certificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), certificateBytes);
        let serverCertificateSignature = try! Ed25519.sign(unsignedServerCertificateData, with: trustRoot)

        //        return SignalProtos.ServerCertificate.newBuilder()
        //            .setCertificate(ByteString.copyFrom(certificateBytes))
        //            .setSignature(ByteString.copyFrom(certificateSignature))
        //            .build();
        let signedServerCertificate = SMKServerCertificate(keyId: keyId,
                                                           key: try! serverKey.ecPublicKey(),
                                                           signatureData: serverCertificateSignature)
        return signedServerCertificate
    }
}
