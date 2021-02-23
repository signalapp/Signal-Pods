//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit
import Curve25519Kit
import SignalClient

// See: https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/certificate/SenderCertificateTest.java
//
//public class SenderCertificateTest extends TestCase {
class SMKSenderCertificateTest: XCTestCase {

    // private final ECKeyPair trustRoot = Curve.generateKeyPair();
    let trustRoot = Curve25519.generateKeyPair()

    // public void testSignature() throws InvalidCertificateException, InvalidKeyException {
    func testSignature() {
        // ECKeyPair serverKey = Curve.generateKeyPair();
        // ECKeyPair key       = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()
        let key       = Curve25519.generateKeyPair()

        // byte[] certificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
        //     .setSender("+14152222222")
        //     .setSenderDevice(1)
        //     .setExpires(31337)
        //     .setIdentityKey(ByteString.copyFrom(key.getPublicKey().serialize()))
        //     .setSigner(getServerCertificate(serverKey))
        //     .build()
        //     .toByteArray();
        let signer = try! getServerCertificate(serverKey: serverKey)
        let builder = try! SMKProtoSenderCertificateCertificate.builder(senderDevice: 1,
                                                                        expires: 31337,
                                                                        identityKey: key.ecPublicKey().serialized,
                                                                        signer: signer)
        builder.setSenderUuid(aliceAddress.uuid!.uuidString)
        let certificateData = try! builder.buildSerializedData()

        // byte[] certificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), certificateBytes);
        let certificateSignature = try! Ed25519.sign(certificateData, with: serverKey)

        // SenderCertificate senderCertificate  = new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
        //     .setCertificate(ByteString.copyFrom(certificateBytes))
        //     .setSignature(ByteString.copyFrom(certificateSignature))
        //     .build()
        //     .toByteArray());
        let senderCertificateData = try! SMKProtoSenderCertificate.builder(certificate: certificateData,
                                                                           signature: certificateSignature)
            .buildSerializedData()
        let senderCertificate = try! SenderCertificate(senderCertificateData)

        // new CertificateValidator(trustRoot.getPublicKey()).validate(senderCertificate, 31336);
        let certificateValidator = try! SMKCertificateDefaultValidator(trustRoot: trustRoot.ecPublicKey())
        XCTAssertNoThrow(try certificateValidator.throwswrapped_validate(senderCertificate: senderCertificate,
                                                                         validationTime: 31336))
    }

    // public void testExpiredSignature() throws InvalidCertificateException, InvalidKeyException {
    func testExpiredSignature() {
        // ECKeyPair serverKey = Curve.generateKeyPair();
        // ECKeyPair key       = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()
        let key = Curve25519.generateKeyPair()

        // byte[] certificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
        //     .setSender("+14152222222")
        //     .setSenderDevice(1)
        //     .setExpires(31337)
        //     .setIdentityKey(ByteString.copyFrom(key.getPublicKey().serialize()))
        //     .setSigner(getServerCertificate(serverKey))
        //     .build()
        //     .toByteArray();
        let signer = try! getServerCertificate(serverKey: serverKey)
        let builder = try! SMKProtoSenderCertificateCertificate.builder(senderDevice: 1,
                                                                        expires: 31337,
                                                                        identityKey: key.ecPublicKey().serialized,
                                                                        signer: signer)
        builder.setSenderUuid(aliceAddress.uuid!.uuidString)
        let certificateData = try! builder.buildSerializedData()

        // byte[] certificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), certificateBytes);
        let certificateSignature = try! Ed25519.sign(certificateData, with: serverKey)

        // SenderCertificate senderCertificate  = new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
        //     .setCertificate(ByteString.copyFrom(certificateBytes))
        //     .setSignature(ByteString.copyFrom(certificateSignature))
        //     .build()
        //     .toByteArray());
        let senderCertificateData = try! SMKProtoSenderCertificate.builder(certificate: certificateData,
                                                                           signature: certificateSignature)
            .buildSerializedData()
        let senderCertificate = try! SenderCertificate(senderCertificateData)

        // try {
        //   new CertificateValidator(trustRoot.getPublicKey()).validate(senderCertificate, 31338);
        //   throw new AssertionError();
        // } catch (InvalidCertificateException e) {
        //   // good
        // }
        let certificateValidator = try! SMKCertificateDefaultValidator(trustRoot: trustRoot.ecPublicKey())
        XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(senderCertificate: senderCertificate, validationTime: 31338))
    }

    // public void testBadSignature() throws InvalidCertificateException, InvalidKeyException {
    func testBadSignature() {
        // ECKeyPair serverKey = Curve.generateKeyPair();
        // ECKeyPair key       = Curve.generateKeyPair();
        let serverKey = Curve25519.generateKeyPair()
        let key = Curve25519.generateKeyPair()

        // byte[] certificateBytes = SignalProtos.SenderCertificate.Certificate.newBuilder()
        //     .setSender("+14152222222")
        //     .setSenderDevice(1)
        //     .setExpires(31337)
        //     .setIdentityKey(ByteString.copyFrom(key.getPublicKey().serialize()))
        //     .setSigner(getServerCertificate(serverKey))
        //     .build()
        //     .toByteArray();
        let signer = try! getServerCertificate(serverKey: serverKey)
        let builder = try! SMKProtoSenderCertificateCertificate.builder(senderDevice: 1,
                                                                        expires: 31337,
                                                                        identityKey: key.ecPublicKey().serialized,
                                                                        signer: signer)
        builder.setSenderUuid(aliceAddress.uuid!.uuidString)
        let certificateData = try! builder.buildSerializedData()

        // byte[] certificateSignature = Curve.calculateSignature(serverKey.getPrivateKey(), certificateBytes);
        let certificateSignature = try! Ed25519.sign(certificateData, with: serverKey)

        // for (int i=0;i<certificateSignature.length;i++) {
        //   for (int b=0;b<8;b++) {
        for i in 0..<certificateSignature.count {
            for b in 0..<8 {
                // byte[] badSignature = new byte[certificateSignature.length];
                // System.arraycopy(certificateSignature, 0, badSignature, 0, certificateSignature.length);
                //
                // badSignature[i] = (byte)(badSignature[i] ^ 1 << b);
                var badSignature = certificateSignature
                badSignature.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
                    bytes[i] = (bytes[i] ^ 1 << b)
                }

                // SenderCertificate senderCertificate = new SenderCertificate(SignalProtos.SenderCertificate.newBuilder()
                //     .setCertificate(ByteString.copyFrom(certificateBytes))
                //     .setSignature(ByteString.copyFrom(badSignature))
                //     .build()
                //     .toByteArray());
                let serializedData = try! SMKProtoSenderCertificate.builder(certificate: certificateData,
                                                                            signature: badSignature).buildSerializedData()
                let senderCertificate = try! SenderCertificate(serializedData)

                // try {
                //   new CertificateValidator(trustRoot.getPublicKey()).validate(senderCertificate, 31336);
                //   throw new AssertionError();
                // } catch (InvalidCertificateException e) {
                //   // good
                // }
                let certificateValidator = try! SMKCertificateDefaultValidator(trustRoot: trustRoot.ecPublicKey())
                XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(senderCertificate: senderCertificate,
                                                                                     validationTime: 31336))
            }
        }
    }

    // MARK: - Utils

    // private SignalProtos.ServerCertificate getServerCertificate(ECKeyPair serverKey) throws InvalidKeyException, InvalidCertificateException {
    private func getServerCertificate(serverKey: ECKeyPair) throws -> SMKProtoServerCertificate {
        // byte[] certificateBytes = SignalProtos.ServerCertificate.Certificate.newBuilder()
        //     .setId(1)
        //     .setKey(ByteString.copyFrom(serverKey.getPublicKey().serialize()))
        //     .build()
        //     .toByteArray();
        let certificateData = try! SMKProtoServerCertificateCertificate.builder(id: 1,
                                                                                key: serverKey.ecPublicKey().serialized)
            .buildSerializedData()

        // byte[] certificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), certificateBytes);
        let certificateSignature = try! Ed25519.sign(certificateData, with: trustRoot)

        // return SignalProtos.ServerCertificate.newBuilder()
        //     .setCertificate(ByteString.copyFrom(certificateBytes))
        //     .setSignature(ByteString.copyFrom(certificateSignature))
        //     .build();
        return try! SMKProtoServerCertificate.builder(certificate: certificateData,
                                                      signature: certificateSignature).build()
    }
}
