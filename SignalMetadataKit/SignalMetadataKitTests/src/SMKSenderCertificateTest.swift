//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import XCTest
import SignalMetadataKit

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
        builder.setSenderE164("+14152222222")
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
        let senderCertificate = try! SMKSenderCertificate(serializedData: senderCertificateData)

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
        builder.setSenderE164("+14152222222")
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
        let senderCertificate = try! SMKSenderCertificate(serializedData: senderCertificateData)

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
        builder.setSenderE164("+14152222222")
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
                let senderCertificate = try! SMKSenderCertificate(serializedData: serializedData)

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

    func test_losslessRoundTrip() {
        // To test a hypothetical addition of a new field:
        //
        // Step 1: tempororarily add a new field to the .proto.
        //
        //     index 537f8df..82e9263 100644
        //     --- a/protobuf/OWSUnidentifiedDelivery.proto
        //     +++ b/protobuf/OWSUnidentifiedDelivery.proto
        //     @@ -40,6 +40,7 @@ message SenderCertificate {
        //     optional bytes identityKey = 4;
        //     // @required
        //     optional ServerCertificate signer = 5;
        //     +        optional string someFakeField = 999;
        //     }
        //
        // Step 2: Serialize and print out the new fixture data (uncomment the following)
        //
        //     let serverKey = Curve25519.generateKeyPair()
        //     let key = Curve25519.generateKeyPair()
        //     let signer = try! getServerCertificate(serverKey: serverKey)
        //     let builder = try! SMKProtoSenderCertificateCertificate.builder(sender: "+14152222222",
        //                                                                     senderDevice: 1,
        //                                                                     expires: 31337,
        //                                                                     identityKey: key.ecPublicKey().serialized,
        //                                                                     signer: signer)
        //     builder.setSomeFakeField("crashing right down")
        //
        //     print("<SNIP>")
        //     let serializedCertificateData = try! builder.buildSerializedData()
        //     let certificateDataEncoded = serializedCertificateData.base64EncodedString()
        //     print("let certificateDataEncoded = \"\(certificateDataEncoded)\"")
        //
        //     let certificateSignatureEncoded = try! Ed25519.sign(serializedCertificateData, with: serverKey).base64EncodedString()
        //     print("let certificateSignatureEncoded = \"\(certificateSignatureEncoded)\"")
        //
        //     let trustRootPublicKeyDataEncoded = try! trustRoot.ecPublicKey().serialized.base64EncodedString()
        //     print("let trustRootPublicKeyDataEncoded = \"\(trustRootPublicKeyDataEncoded)\"")
        //     print("</SNIP>")

        // Step 3: update the following *Encoded fixture data with the new values from above.
        let certificateDataEncoded = "CgwrMTQxNTIyMjIyMjIQARlpegAAAAAAACIhBdyYGjVpE02g7CUlCvGNElHZNZmGy3Xhh5y+TuPh6dQIKmkKJQgBEiEFeszl2BGIxS95K+anx30GX6+Tgoqp70/aWKNEkH/5TGkSQPbz1mzKfidiWTuT8pRdnYYchEnL+ln5i/mVq5JP1MzzmqVnx8bzkFhfT4EGYSDY5rQoVfb5JnV0Kf3Aavdkd426PhNjcmFzaGluZyByaWdodCBkb3du"
        let certificateSignatureEncoded = "Ii8DBO6yapzQwc0kJ6M5EhuFsgHccjlzFSJow408O1tceRVZiYGpR5MZO1SBgKHH2GEayiBNpvayFIL2i4POig=="
        let trustRootPublicKeyDataEncoded = "BanGdQtiGO0KYbSu/rBz3MZvO+LGkjGVceXfmQV8eNwM"

        let certificateData = Data(base64Encoded: certificateDataEncoded)!
        let certificateSignature = Data(base64Encoded: certificateSignatureEncoded)!
        let trustRootPublicKeyData = Data(base64Encoded: trustRootPublicKeyDataEncoded)!

        // The rest of the test should be stable.
        let senderCertificateData = try! SMKProtoSenderCertificate.builder(certificate: certificateData,
                                                                           signature: certificateSignature)
            .buildSerializedData()

        let senderCertificate = try! SMKSenderCertificate(serializedData: senderCertificateData)

        let stableTrustRoot = try! ECPublicKey(serializedKeyData: trustRootPublicKeyData)

        let certificateValidator = SMKCertificateDefaultValidator(trustRoot: stableTrustRoot)
        XCTAssertNoThrow(try certificateValidator.throwswrapped_validate(senderCertificate: senderCertificate,
                                                                         validationTime: 31336))
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
