//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import XCTest
import SwiftProtobuf
import SignalMetadataKit

// See: https://github.com/signalapp/libsignal-metadata-java/blob/master/tests/src/test/java/org/signal/libsignal/metadata/certificate/ServerCertificateTest.java
//
// public class ServerCertificateTest extends TestCase {
class SMKServerCertificateTest: XCTestCase {

    // public void testBadFields() {
    func testBadFields() {
        // NOTE: We don't want to (and can't) test this.
        // Our Swift proto wrappers ensure that we never have missing fields.

        // SignalProtos.ServerCertificate.Certificate.Builder certificate = SignalProtos.ServerCertificate.Certificate.newBuilder();
        //
        // try {
        //   new ServerCertificate(SignalProtos.ServerCertificate.newBuilder().setSignature(ByteString.copyFrom(new byte[64])).build().toByteArray());
        //   throw new AssertionError();
        // } catch (InvalidCertificateException e) {
        //   // good
        // }
        //
        // try {
        //   new ServerCertificate(SignalProtos.ServerCertificate.newBuilder().setCertificate(certificate.build().toByteString())
        //      .setSignature(ByteString.copyFrom(new byte[64])).build().toByteArray());
        //   throw new AssertionError();
        // } catch (InvalidCertificateException e) {
        //   // good
        // }
        //
        // try {
        //   new ServerCertificate(SignalProtos.ServerCertificate.newBuilder().setCertificate(certificate.setId(1).build().toByteString())
        //       .setSignature(ByteString.copyFrom(new byte[64])).build().toByteArray());
        //   throw new AssertionError();
        // } catch (InvalidCertificateException e) {
        //   // good
        // }
    }

    // public void testSignature() throws InvalidKeyException, InvalidCertificateException {
    func testSignature() {
        // ECKeyPair trustRoot = Curve.generateKeyPair();
        // ECKeyPair keyPair   = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()
        let keyPair = Curve25519.generateKeyPair()

        // SignalProtos.ServerCertificate.Certificate certificate = SignalProtos.ServerCertificate.Certificate.newBuilder()
        //     .setId(1)
        //     .setKey(ByteString.copyFrom(keyPair.getPublicKey().serialize()))
        //     .build();
        let certificateBuilder = SMKProtoServerCertificateCertificate.builder(id: 1,
                                                                              key: try! keyPair.ecPublicKey().serialized)
        // byte[] certificateBytes     = certificate.toByteArray();
        let certificateData = try! certificateBuilder.build().serializedData()

        // byte[] certificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), certificateBytes);
        let certificateSignature = try! Ed25519.sign(certificateData, with: trustRoot)

        // byte[] serialized = SignalProtos.ServerCertificate.newBuilder()
        //     .setCertificate(ByteString.copyFrom(certificateBytes))
        //     .setSignature(ByteString.copyFrom(certificateSignature))
        //     .build().toByteArray();
        //
        let serializedData = try! SMKProtoServerCertificate.builder(certificate: certificateData,
                                                                    signature: certificateSignature)
            .buildSerializedData()

        // new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
        let serverCertificate = try! SMKServerCertificate(serializedData: serializedData)
        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
        try! certificateValidator.throwswrapped_validate(serverCertificate: serverCertificate)
    }

    // public void testBadSignature() throws Exception {
    func testBadSignature() {
        // ECKeyPair trustRoot = Curve.generateKeyPair();
        // ECKeyPair keyPair   = Curve.generateKeyPair();
        let trustRoot = Curve25519.generateKeyPair()
        let keyPair = Curve25519.generateKeyPair()

        // SignalProtos.ServerCertificate.Certificate certificate = SignalProtos.ServerCertificate.Certificate.newBuilder()
        //     .setId(1)
        //     .setKey(ByteString.copyFrom(keyPair.getPublicKey().serialize()))
        //     .build();
        let certificate = try! SMKProtoServerCertificateCertificate.builder(id: 1,
                                                                            key: try! keyPair.ecPublicKey().serialized)
            .build()

        // byte[] certificateBytes     = certificate.toByteArray();
        let certificateData = try! certificate.serializedData()

        // byte[] certificateSignature = Curve.calculateSignature(trustRoot.getPrivateKey(), certificateBytes);
        let certificateSignature = try! Ed25519.sign(certificateData, with: trustRoot)

        // for (int i=0;i<certificateSignature.length;i++) {
        //   for (int b=0;b<8;b++) {
        for i in 0..<certificateSignature.count {
            for b in 0..<8 {
                // byte[] badSignature = new byte[certificateSignature.length];
                // System.arraycopy(certificateSignature, 0, badSignature, 0, badSignature.length);
                //
                // badSignature[i] = (byte) (badSignature[i] ^ (1 << b));
                var badSignature = certificateSignature
                badSignature.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
                    bytes[i] = (bytes[i] ^ 1 << b)
                }

                // byte[] serialized = SignalProtos.ServerCertificate.newBuilder()
                //     .setCertificate(ByteString.copyFrom(certificateBytes))
                //     .setSignature(ByteString.copyFrom(badSignature))
                //     .build().toByteArray();
                let serializedData = try! SMKProtoServerCertificate.builder(certificate: certificateData,
                                                                            signature: badSignature)
                    .buildSerializedData()

                // try {
                //   new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
                //   throw new AssertionError();
                // } catch (InvalidCertificateException e) {
                //   // good
                // }
                let serverCertificate = try! SMKServerCertificate(serializedData: serializedData)
                let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
                XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(serverCertificate: serverCertificate))
            }
        }

        // for (int i=0;i<certificateBytes.length;i++) {
        //   for (int b=0;b<8;b++) {
        for i in 0..<certificateData.count {
            for b in 0..<8 {
                // byte[] badCertificate = new byte[certificateBytes.length];
                // System.arraycopy(certificateBytes, 0, badCertificate, 0, badCertificate.length);
                //
                // badCertificate[i] = (byte) (badCertificate[i] ^ (1 << b));
                var badCertificate = certificateData
                badCertificate.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
                    bytes[i] = (bytes[i] ^ 1 << b)
                }

                // byte[] serialized = SignalProtos.ServerCertificate.newBuilder()
                //     .setCertificate(ByteString.copyFrom(badCertificate))
                //     .setSignature(ByteString.copyFrom(certificateSignature))
                //     .build().toByteArray();
                let serializedData = try! SMKProtoServerCertificate.builder(certificate: badCertificate,
                                                                            signature: certificateSignature)
                    .buildSerializedData()

                // try {
                //   new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
                //   throw new AssertionError();
                // } catch (InvalidCertificateException e) {
                //   // good
                // }
                let serverCertificate: SMKServerCertificate
                do {
                    serverCertificate = try SMKServerCertificate(serializedData: serializedData)
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
                } catch ECKeyError.assertionError {
                    // Some bad certificates will fail to parse.
                    continue
                } catch {
                    XCTFail("Unexpected parsing error: \(error)")
                    continue
                }

                // try {
                //   new CertificateValidator(trustRoot.getPublicKey()).validate(new ServerCertificate(serialized));
                //   throw new AssertionError();
                // } catch (InvalidCertificateException e) {
                //   // good
                // }
                let certificateValidator = SMKCertificateDefaultValidator(trustRoot: try! trustRoot.ecPublicKey())
                XCTAssertThrowsError(try certificateValidator.throwswrapped_validate(serverCertificate: serverCertificate))
            }
        }
    }
}
