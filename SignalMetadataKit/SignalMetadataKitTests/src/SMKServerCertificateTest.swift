//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import XCTest
import SwiftProtobuf
import SignalMetadataKit

// See: https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/certificate/ServerCertificateTest.java
//
// public class ServerCertificateTest extends TestCase {
class SMKServerCertificateTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
}

//    public void testBadFields() {
    func testBadFields() {

        // NOTE: We don't want to (and can't) test this.
        // Our Swift proto wrappers ensure that we never have missing fields.

//    SignalProtos.ServerCertificate.Certificate.Builder certificate = SignalProtos.ServerCertificate.Certificate.newBuilder();
//
//    try {
//    new ServerCertificate(SignalProtos.ServerCertificate.newBuilder().setSignature(ByteString.copyFrom(new byte[64])).build().toByteArray());
//    throw new AssertionError();
//    } catch (InvalidCertificateException e) {
//    // good
//    }
//
//    try {
//    new ServerCertificate(SignalProtos.ServerCertificate.newBuilder().setCertificate(certificate.build().toByteString())
//    .setSignature(ByteString.copyFrom(new byte[64])).build().toByteArray());
//    throw new AssertionError();
//    } catch (InvalidCertificateException e) {
//    // good
//    }
//
//    try {
//    new ServerCertificate(SignalProtos.ServerCertificate.newBuilder().setCertificate(certificate.setId(1).build().toByteString())
//    .setSignature(ByteString.copyFrom(new byte[64])).build().toByteArray());
//    throw new AssertionError();
//    } catch (InvalidCertificateException e) {
//    // good
//    }
    }

//    public void testSignature() throws InvalidKeyException, InvalidCertificateException {
    func testSignature() {
//    ECKeyPair trustRoot = Curve.generateKeyPair();
//    ECKeyPair keyPair   = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()
        let keyPair = Curve25519.generateKeyPair()

//    SignalProtos.ServerCertificate.Certificate certificate = SignalProtos.ServerCertificate.Certificate.newBuilder()
//    .setId(1)
//    .setKey(ByteString.copyFrom(keyPair.getPublicKey().serialize()))
//    .build();
        let keyId: UInt32 = 1
        let unsignedServerCertificateBuilder = SMKProtoServerCertificateCertificate.builder(id: keyId,
                                                                                            key: try! keyPair.ecPublicKey().serialized)

        //    byte[] certificateBytes     = certificate.toByteArray();
        let unsignedServerCertificateData = try! unsignedServerCertificateBuilder.build().serializedData()

//        byte[] certificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), certificateBytes);
        let serverCertificateSignature = try! Ed25519.sign(unsignedServerCertificateData, with: trustRoot)

//    byte[] serialized = SignalProtos.ServerCertificate.newBuilder()
//    .setCertificate(ByteString.copyFrom(certificateBytes))
//    .setSignature(ByteString.copyFrom(certificateSignature))
//    .build().toByteArray();
        let signedServerCertificate = SMKServerCertificate(keyId: keyId,
                                                           key: try! keyPair.ecPublicKey(),
                                                           signatureData: serverCertificateSignature)
        let serializedData = try! signedServerCertificate.serialized()
        let parsed = try! SMKServerCertificate.parse(data: serializedData)

//    new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
        try! certificateValidator.throwswrapped_validate(serverCertificate: parsed)
    }

//    public void testBadSignature() throws Exception {
    func testBadSignature() {
//    ECKeyPair trustRoot = Curve.generateKeyPair();
//    ECKeyPair keyPair   = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()
        let keyPair = Curve25519.generateKeyPair()

//    SignalProtos.ServerCertificate.Certificate certificate = SignalProtos.ServerCertificate.Certificate.newBuilder()
//    .setId(1)
//    .setKey(ByteString.copyFrom(keyPair.getPublicKey().serialize()))
//    .build();
        let keyId: UInt32 = 1
        let unsignedServerCertificateBuilder = SMKProtoServerCertificateCertificate.builder(id: keyId,
                                                                                            key: try! keyPair.ecPublicKey().serialized)

//    byte[] certificateBytes     = certificate.toByteArray();
        let unsignedServerCertificateData = try! unsignedServerCertificateBuilder.build().serializedData()

//    byte[] certificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), certificateBytes);
        let serverCertificateSignature = try! Ed25519.sign(unsignedServerCertificateData, with: trustRoot)

//    for (int i=0;i<certificateSignature.length;i++) {
        for i in 0..<serverCertificateSignature.count {
//    for (int b=0;b<8;b++) {
            for b in 0..<8 {
//    byte[] badSignature = new byte[certificateSignature.length];
//    System.arraycopy(certificateSignature, 0, badSignature, 0, badSignature.length);
                var badSignature = serverCertificateSignature

//    badSignature[i] = (byte) (badSignature[i] ^ (1 << b));
                badSignature.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
                    bytes[i] = (UInt8)(bytes[i] ^ 1 << b)
                }

//    byte[] serialized = SignalProtos.ServerCertificate.newBuilder()
//    .setCertificate(ByteString.copyFrom(certificateBytes))
//    .setSignature(ByteString.copyFrom(badSignature))
//    .build().toByteArray();
                let signedServerCertificate = SMKServerCertificate(keyId: keyId,
                                                                   key: try! keyPair.ecPublicKey(),
                                                                   signatureData: badSignature)
                let serializedData = try! signedServerCertificate.serialized()
                let parsed = try! SMKServerCertificate.parse(data: serializedData)

//    try {
//    new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
//    throw new AssertionError();
//    } catch (InvalidCertificateException e) {
//    // good
//    }
                let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
                XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(serverCertificate: parsed))
            }
        }

//    for (int i=0;i<certificateBytes.length;i++) {
        for i in 0..<unsignedServerCertificateData.count {
//    for (int b=0;b<8;b++) {
            for b in 0..<8 {
//    byte[] badCertificate = new byte[certificateBytes.length];
//    System.arraycopy(certificateBytes, 0, badCertificate, 0, badCertificate.length);
                var badCertificate = unsignedServerCertificateData

//    badCertificate[i] = (byte) (badCertificate[i] ^ (1 << b));
                badCertificate.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
                    bytes[i] = (UInt8)(bytes[i] ^ 1 << b)
                }

//    byte[] serialized = SignalProtos.ServerCertificate.newBuilder()
//    .setCertificate(ByteString.copyFrom(badCertificate))
//    .setSignature(ByteString.copyFrom(certificateSignature))
//    .build().toByteArray();
                let builder =
                    SMKProtoServerCertificate.builder(certificate: badCertificate, signature: serverCertificateSignature)
                let serializedData = try! builder.buildSerializedData()
                let parsed: SMKServerCertificate
                do {
                    parsed = try SMKServerCertificate.parse(data: serializedData)
                } catch BinaryDecodingError.malformedProtobuf {
                    // Some bad certificates will fail to parse.
                    continue
                } catch BinaryDecodingError.truncated {
                    // Some bad certificates will fail to parse.
                    continue
                } catch SMKProtoError.invalidProtobuf {
                    // Some bad certificates will fail to parse.
                    continue
                } catch SMKError.assertionError {
                    // Some bad certificates will fail to parse.
                    continue
                } catch {
                    XCTFail("Unexpected parsing error: \(error)")
                    continue
                }
//
//    try {
//    new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
//    throw new AssertionError();
//    } catch (InvalidCertificateException e) {
//    // good
//    }
                //    }
                let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
                XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(serverCertificate: parsed))
            }
        }
    }
}
