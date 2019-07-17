//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

// See:
// https://github.com/signalapp/libsignal-metadata-java/blob/cac0dde9de416a192e64a8940503982820870090/java/src/main/java/org/signal/libsignal/metadata/certificate/SenderCertificate.java
@objc
public class SMKSenderCertificate: NSObject {

    // private final ServerCertificate signer;
    // private final ECPublicKey       key;
    // private final int               senderDeviceId;
    // private final String            sender;
    // private final long              expiration;
    public let signer: SMKServerCertificate
    public let key: ECPublicKey
    public let senderDeviceId: UInt32
    public let senderAddress: SMKAddress
    public let expirationTimestamp: UInt64

    // private final byte[] serialized;
    // private final byte[] certificate;
    // private final byte[] signature;
    public let serializedData: Data
    public let certificateData: Data
    public let signatureData: Data

    public init(serializedData: Data) throws {
        // SignalProtos.SenderCertificate wrapper = SignalProtos.SenderCertificate.parseFrom(serialized);
        //
        // if (!wrapper.hasSignature() || !wrapper.hasCertificate()) {
        //     throw new InvalidCertificateException("Missing fields");
        // }
        let wrapperProto = try SMKProtoSenderCertificate.parseData(serializedData)

        // SignalProtos.SenderCertificate.Certificate certificate = SignalProtos.SenderCertificate.Certificate.parseFrom(wrapper.getCertificate());
        //
        // if (!certificate.hasSigner() || !certificate.hasIdentityKey() || !certificate.hasSenderDevice() || !certificate.hasExpires() || !certificate.hasSender()) {
        //     throw new InvalidCertificateException("Missing fields");
        // }
        let certificateProto = try SMKProtoSenderCertificateCertificate.parseData(wrapperProto.certificate)

        // this.signer         = new ServerCertificate(certificate.getSigner().toByteArray());
        // this.key            = Curve.decodePoint(certificate.getIdentityKey().toByteArray(), 0);
        self.signer = try SMKServerCertificate(serializedData: certificateProto.signer.serializedData())
        self.key = try ECPublicKey(serializedKeyData: certificateProto.identityKey)

        // this.sender         = certificate.getSender();
        let senderE164 = certificateProto.senderE164
        let senderUuid: UUID?
        if let senderUuidString = certificateProto.senderUuid {
            senderUuid = UUID(uuidString: senderUuidString)
            assert(senderUuid != nil)
        } else {
            senderUuid = nil
        }
        self.senderAddress = try SMKAddress(uuid: senderUuid, e164: senderE164)

        // this.senderDeviceId = certificate.getSenderDevice();
        // this.expiration     = certificate.getExpires();
        self.senderDeviceId = certificateProto.senderDevice
        self.expirationTimestamp = certificateProto.expires

        // this.serialized  = serialized;
        // this.certificate = wrapper.getCertificate().toByteArray();
        // this.signature   = wrapper.getSignature().toByteArray();
        self.serializedData = serializedData
        self.certificateData = wrapperProto.certificate
        self.signatureData = wrapperProto.signature
    }
}
