//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

// See:
// https://github.com/signalapp/libsignal-metadata-java/blob/cac0dde9de416a192e64a8940503982820870090/java/src/main/java/org/signal/libsignal/metadata/certificate/SenderCertificate.java
@objc public class SMKSenderCertificate: NSObject {

    @objc public let signer: SMKServerCertificate
    @objc public let key: ECPublicKey
    @objc public let senderDeviceId: UInt32
    @objc public let senderRecipientId: String
    @objc public let expirationTimestamp: UInt64
    @objc public let signatureData: Data

    @objc public init(signer: SMKServerCertificate,
                      key: ECPublicKey,
                      senderDeviceId: UInt32,
                      senderRecipientId: String,
                      expirationTimestamp: UInt64,
                      signatureData: Data) {
        self.signer = signer
        self.key = key
        self.senderDeviceId = senderDeviceId
        self.senderRecipientId = senderRecipientId
        self.expirationTimestamp = expirationTimestamp
        self.signatureData = signatureData
    }

    @objc public class func parse(data: Data) throws -> SMKSenderCertificate {
        let proto = try SMKProtoSenderCertificate.parseData(data)
        return try parse(proto: proto)
    }

    @objc public class func parse(proto: SMKProtoSenderCertificate) throws -> SMKSenderCertificate {

        let certificateData = proto.certificate
        let signatureData = proto.signature

        let certificateProto = try SMKProtoSenderCertificateCertificate.parseData(certificateData)

        let keyData = certificateProto.identityKey
        let key = try ECPublicKey(serializedKeyData: keyData)
        let senderDeviceId = certificateProto.senderDevice
        let senderRecipientId = certificateProto.sender
        let expirationTimestamp = certificateProto.expires
        let signerProto = certificateProto.signer
        let signer = try SMKServerCertificate.parse(proto: signerProto)

        return SMKSenderCertificate(signer: signer, key: key, senderDeviceId: senderDeviceId, senderRecipientId: senderRecipientId, expirationTimestamp: expirationTimestamp, signatureData: signatureData)
    }

    @objc public func toProto() throws -> SMKProtoSenderCertificate {
        let certificateBuilder = SMKProtoSenderCertificateCertificate.builder(sender: senderRecipientId,
                                                                              senderDevice: senderDeviceId,
                                                                              expires: expirationTimestamp,
                                                                              identityKey: key.serialized,
                                                                              signer: try signer.toProto())

        let builder =
            SMKProtoSenderCertificate.builder(certificate: try certificateBuilder.buildSerializedData(),
                                              signature: signatureData)
        return try builder.build()
    }

    @objc public func serialized() throws -> Data {
        return try toProto().serializedData()
    }

    open override func isEqual(_ other: Any?) -> Bool {
        if let other = other as? SMKSenderCertificate {
            return (signer.isEqual(other.signer) &&
                key.isEqual(other.key) &&
                senderDeviceId == other.senderDeviceId &&
                senderRecipientId == other.senderRecipientId &&
                expirationTimestamp == other.expirationTimestamp &&
                signatureData == other.signatureData)
        } else {
            return false
        }
    }

    public override var hash: Int {
        return signer.hashValue ^ key.hashValue ^ senderDeviceId.hashValue ^ senderRecipientId.hashValue ^ expirationTimestamp.hashValue ^ signatureData.hashValue
    }
}
