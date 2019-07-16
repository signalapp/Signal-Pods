//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

// https://github.com/signalapp/libsignal-metadata-java/blob/master/java/src/main/java/org/signal/libsignal/metadata/protocol/UnidentifiedSenderMessage.java
@objc public class SMKUnidentifiedSenderMessage: NSObject {

    // private static final int CIPHERTEXT_VERSION = 1;
    @objc public static let kSMKMessageCipherTextVersion: UInt = 1

    // private final int         version;
    // private final ECPublicKey ephemeral;
    // private final byte[]      encryptedStatic;
    // private final byte[]      encryptedMessage;
    // private final byte[]      serialized;
    public let cipherTextVersion: UInt
    public let ephemeralKey: ECPublicKey
    public let encryptedStatic: Data
    public let encryptedMessage: Data
    public let serializedData: Data

    // public UnidentifiedSenderMessage(byte[] serialized) throws InvalidMetadataMessageException, InvalidMetadataVersionException
    public init(serializedData: Data) throws {
        let parser = OWSDataParser(data: serializedData)

        // this.version = ByteUtil.highBitsToInt(serialized[0]);
        // if (version > CIPHERTEXT_VERSION) {
        //   throw new InvalidMetadataVersionException("Unknown version: " + this.version);
        // }
        let versionByte = try parser.nextByte(name: "version byte")
        self.cipherTextVersion = UInt(SerializationUtilities.highBitsToInt(fromByte: versionByte))
        guard cipherTextVersion <= SMKUnidentifiedSenderMessage.kSMKMessageCipherTextVersion else {
            throw SMKError.assertionError(description: "\(type(of: self)) unknown cipherTextVersion: \(cipherTextVersion)")
        }

        // SignalProtos.UnidentifiedSenderMessage unidentifiedSenderMessage =
        //     SignalProtos.UnidentifiedSenderMessage.parseFrom(ByteString.copyFrom(serialized, 1, serialized.length - 1));
        // if (!unidentifiedSenderMessage.hasEphemeralPublic() ||
        //     !unidentifiedSenderMessage.hasEncryptedStatic() ||
        //     !unidentifiedSenderMessage.hasEncryptedMessage())
        // {
        //   throw new InvalidMetadataMessageException("Missing fields");
        // }
        let protoData = try parser.remainder(name: "proto data")
        let proto = try SMKProtoUnidentifiedSenderMessage.parseData(protoData)

        // this.ephemeral        = Curve.decodePoint(unidentifiedSenderMessage.getEphemeralPublic().toByteArray(), 0);
        self.ephemeralKey = try ECPublicKey(serializedKeyData: proto.ephemeralPublic)

        // this.encryptedStatic  = unidentifiedSenderMessage.getEncryptedStatic().toByteArray();
        // this.encryptedMessage = unidentifiedSenderMessage.getEncryptedMessage().toByteArray();
        // this.serialized       = serialized;
        self.encryptedStatic = proto.encryptedStatic
        self.encryptedMessage = proto.encryptedMessage
        self.serializedData = serializedData

        // } catch (InvalidProtocolBufferException | InvalidKeyException e) {
        //   throw new InvalidMetadataMessageException(e);
        // }
    }

    // public UnidentifiedSenderMessage(ECPublicKey ephemeral, byte[] encryptedStatic, byte[] encryptedMessage) {
    public init(ephemeralKey: ECPublicKey, encryptedStatic: Data, encryptedMessage: Data) throws {
        // this.version          = CIPHERTEXT_VERSION;
        // this.ephemeral        = ephemeral;
        // this.encryptedStatic  = encryptedStatic;
        // this.encryptedMessage = encryptedMessage;
        self.cipherTextVersion = SMKUnidentifiedSenderMessage.kSMKMessageCipherTextVersion
        self.ephemeralKey = ephemeralKey
        self.encryptedStatic = encryptedStatic
        self.encryptedMessage = encryptedMessage

        // byte[] versionBytes = {ByteUtil.intsToByteHighAndLow(CIPHERTEXT_VERSION, CIPHERTEXT_VERSION)};
        let versionByte: UInt8 = UInt8((self.cipherTextVersion << 4 | self.cipherTextVersion) & 0xFF)
        let versionBytes = [versionByte]
        let versionData = Data(versionBytes)

        // byte[] messageBytes = SignalProtos.UnidentifiedSenderMessage.newBuilder()
        //     .setEncryptedMessage(ByteString.copyFrom(encryptedMessage))
        //     .setEncryptedStatic(ByteString.copyFrom(encryptedStatic))
        //     .setEphemeralPublic(ByteString.copyFrom(ephemeral.serialize()))
        //     .build()
        //     .toByteArray();
        let messageData = try SMKProtoUnidentifiedSenderMessage.builder(ephemeralPublic: ephemeralKey.serialized,
                                                                        encryptedStatic: encryptedStatic,
                                                                        encryptedMessage: encryptedMessage).buildSerializedData()

        // this.serialized = ByteUtil.combine(versionBytes, messageBytes);
        self.serializedData = NSData.join([versionData, messageData])
    }
}
