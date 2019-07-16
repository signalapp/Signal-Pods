//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc public enum SMKMessageType: Int {
    case whisper
    case prekey
}

// See:
// https://github.com/signalapp/libsignal-metadata-java/blob/0cbbbf23eaf9f46fdf2d9463f3dfab2fb3271292/java/src/main/java/org/signal/libsignal/metadata/protocol/UnidentifiedSenderMessageContent.java
@objc public class SMKUnidentifiedSenderMessageContent: NSObject {

    // private final int               type;
    // private final SenderCertificate senderCertificate;
    // private final byte[]            content;
    // private final byte[]            serialized;
    public let messageType: SMKMessageType
    public let senderCertificate: SMKSenderCertificate
    public let contentData: Data
    public let serializedData: Data

    // public UnidentifiedSenderMessageContent(byte[] serialized) throws InvalidMetadataMessageException, InvalidCertificateException {
    public init(serializedData: Data) throws {
        // SignalProtos.UnidentifiedSenderMessage.Message message = SignalProtos.UnidentifiedSenderMessage.Message.parseFrom(serialized);
        //
        // if (!message.hasType() || !message.hasSenderCertificate() || !message.hasContent()) {
        //  throw new InvalidMetadataMessageException("Missing fields");
        // }
        let proto = try SMKProtoUnidentifiedSenderMessageMessage.parseData(serializedData)

        // switch (message.getType()) {
        // case MESSAGE:        this.type = CiphertextMessage.WHISPER_TYPE;        break;
        // case PREKEY_MESSAGE: this.type = CiphertextMessage.PREKEY_TYPE;         break;
        // default:             throw new InvalidMetadataMessageException("Unknown type: " + message.getType().getNumber());
        // }
        switch (proto.type) {
        case .prekeyMessage?:
            self.messageType = .prekey
        case .message?:
            self.messageType = .whisper
        default:
            throw SMKProtoError.invalidProtobuf(description: "\(type(of: self)) missing required field: proto.type")
        }

        // this.senderCertificate = new SenderCertificate(message.getSenderCertificate().toByteArray());
        // this.content           = message.getContent().toByteArray();
        // this.serialized        = serialized;
        self.senderCertificate = try SMKSenderCertificate(serializedData: proto.senderCertificate.serializedData())
        self.contentData = proto.content
        self.serializedData = serializedData
    }

    // public UnidentifiedSenderMessageContent(int type, SenderCertificate senderCertificate, byte[] content) {
    public init(messageType: SMKMessageType, senderCertificate: SMKSenderCertificate, contentData: Data) throws {
        // try {
        //   this.serialized = SignalProtos.UnidentifiedSenderMessage.Message.newBuilder()
        //    .setType(SignalProtos.UnidentifiedSenderMessage.Message.Type.valueOf(getProtoType(type)))
        //    .setSenderCertificate(SignalProtos.SenderCertificate.parseFrom(senderCertificate.getSerialized()))
        //    .setContent(ByteString.copyFrom(content))
        //    .build()
        //    .toByteArray();
        let senderCertificateProto = try SMKProtoSenderCertificate.parseData(senderCertificate.serializedData)
        let messageProtoBuilder = SMKProtoUnidentifiedSenderMessageMessage.builder(senderCertificate: senderCertificateProto,
                                                                                   content: contentData)
        messageProtoBuilder.setType(messageType.protoType)
        self.serializedData = try messageProtoBuilder.buildSerializedData()

        // this.type = type;
        // this.senderCertificate = senderCertificate;
        // this.content = content;
        self.messageType = messageType
        self.senderCertificate = senderCertificate
        self.contentData = contentData

        // } catch (InvalidProtocolBufferException e) {
        //   throw new AssertionError(e);
        // }
    }
}

fileprivate extension SMKMessageType {
    // private int getProtoType(int type) {
    var protoType: SMKProtoUnidentifiedSenderMessageMessage.SMKProtoUnidentifiedSenderMessageMessageType {
        // switch (type) {
        // case CiphertextMessage.WHISPER_TYPE: return SignalProtos.UnidentifiedSenderMessage.Message.Type.MESSAGE_VALUE;
        // case CiphertextMessage.PREKEY_TYPE:  return SignalProtos.UnidentifiedSenderMessage.Message.Type.PREKEY_MESSAGE_VALUE;
        // default:                             throw new AssertionError(type);
        // }
        switch self {
        case .whisper:
            return .message
        case .prekey:
            return .prekeyMessage
        }
    }
}
