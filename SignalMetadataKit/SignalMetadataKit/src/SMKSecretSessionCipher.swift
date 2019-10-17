//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class SecretSessionKnownSenderError: NSObject, CustomNSError {
    @objc
    public static let kSenderE164Key = "kSenderE164Key"

    @objc
    public static let kSenderUuidKey = "kSenderUuidKey"

    @objc
    public static let kSenderDeviceIdKey = "kSenderDeviceIdKey"

    public let senderAddress: SMKAddress
    public let senderDeviceId: UInt32
    public let underlyingError: Error

    init(senderAddress: SMKAddress, senderDeviceId: UInt32, underlyingError: Error) {
        self.senderAddress = senderAddress
        self.senderDeviceId = senderDeviceId
        self.underlyingError = underlyingError
    }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [
            type(of: self).kSenderDeviceIdKey: self.senderDeviceId,
            NSUnderlyingErrorKey: (underlyingError as NSError)
        ]

        if let e164 = senderAddress.e164 {
            info[type(of: self).kSenderE164Key] = e164
        }

        if let uuid = senderAddress.uuid {
            info[type(of: self).kSenderUuidKey] = uuid
        }

        return info
    }
}

@objc
public enum SMKSecretSessionCipherError: Int, Error {
    case selfSentMessage
}

// MARK: -

private class SMKSecretKeySpec: NSObject {

    @objc public let keyData: Data
    @objc public let algorithm: String

    init(keyData: Data, algorithm: String) {
        self.keyData = keyData
        self.algorithm = algorithm
    }
}

// MARK: -

private class SMKEphemeralKeys: NSObject {

    @objc public let chainKey: Data
    @objc public let cipherKey: SMKSecretKeySpec
    @objc public let macKey: SMKSecretKeySpec

    init(chainKey: Data, cipherKey: Data, macKey: Data) {
        self.chainKey = chainKey
        self.cipherKey = SMKSecretKeySpec(keyData: cipherKey, algorithm: "AES")
        self.macKey = SMKSecretKeySpec(keyData: macKey, algorithm: "HmacSHA256")
    }
}

// MARK: -

private class SMKStaticKeys: NSObject {

    @objc public let cipherKey: SMKSecretKeySpec
    @objc public let macKey: SMKSecretKeySpec

    init(cipherKey: Data, macKey: Data) {
        self.cipherKey = SMKSecretKeySpec(keyData: cipherKey, algorithm: "AES")
        self.macKey = SMKSecretKeySpec(keyData: macKey, algorithm: "HmacSHA256")
    }
}

// MARK: -

@objc
public class SMKDecryptResult: NSObject {

    public let senderAddress: SMKAddress

    @objc public var senderE164: String? {
        return senderAddress.e164
    }

    @objc public var senderUuid: UUID? {
        return senderAddress.uuid
    }

    @objc public let senderDeviceId: Int
    @objc public let paddedPayload: Data
    @objc public let messageType: SMKMessageType

    init(senderAddress: SMKAddress,
         senderDeviceId: Int,
         paddedPayload: Data,
         messageType: SMKMessageType) {
        self.senderAddress = senderAddress
        self.senderDeviceId = senderDeviceId
        self.paddedPayload = paddedPayload
        self.messageType = messageType
    }
}

// MARK: -

@objc public class SMKSecretSessionCipher: NSObject {

    private let kUDPrefixString = "UnidentifiedDelivery"

    private let kSMKSecretSessionCipherMacLength: UInt = 10

    private let sessionStore: SessionStore
    private let preKeyStore: PreKeyStore
    private let signedPreKeyStore: SignedPreKeyStore
    private let identityStore: IdentityKeyStore

    // public SecretSessionCipher(SignalProtocolStore signalProtocolStore) {
    @objc public init(sessionStore: SessionStore,
                      preKeyStore: PreKeyStore,
                      signedPreKeyStore: SignedPreKeyStore,
                      identityStore: IdentityKeyStore) throws {

        self.sessionStore = sessionStore
        self.preKeyStore = preKeyStore
        self.signedPreKeyStore = signedPreKeyStore
        self.identityStore = identityStore
    }

    // MARK: - Public

    // public byte[] encrypt(SignalProtocolAddress destinationAddress, SenderCertificate senderCertificate, byte[] paddedPlaintext)
    @objc
    public func throwswrapped_encryptMessage(recipientId: String,
                                             deviceId: Int32,
                                             paddedPlaintext: Data,
                                             senderCertificate: SMKSenderCertificate,
                                             protocolContext: SPKProtocolWriteContext?) throws -> Data {
        guard recipientId.count > 0 else {
            throw SMKError.assertionError(description: "\(SMKSecretSessionCipher.logTag) invalid recipientId")
        }
        guard deviceId > 0 else {
            throw SMKError.assertionError(description: "\(SMKSecretSessionCipher.logTag) invalid deviceId")
        }

        // CiphertextMessage message = new SessionCipher(signalProtocolStore, destinationAddress).encrypt(paddedPlaintext);
        let cipher = SessionCipher(sessionStore: sessionStore,
                                   preKeyStore: preKeyStore,
                                   signedPreKeyStore: signedPreKeyStore,
                                   identityKeyStore: identityStore,
                                   recipientId: recipientId,
                                   deviceId: deviceId)
        let encryptedMessage = try cipher.encryptMessage(paddedPlaintext, protocolContext: protocolContext)

        // IdentityKeyPair ourIdentity = signalProtocolStore.getIdentityKeyPair();
        guard let ourIdentityKeyPair = identityStore.identityKeyPair(protocolContext) else {
            throw SMKError.assertionError(description: "\(logTag) Missing our identity key pair.")
        }

        // ECPublicKey theirIdentity = signalProtocolStore.getIdentity(destinationAddress).getPublicKey();
        guard let theirIdentityKeyData = identityStore.identityKey(forRecipientId: recipientId, protocolContext: protocolContext) else {
            throw SMKError.assertionError(description: "\(logTag) Missing their public identity key.")
        }

        // NOTE: we don't use ECPublicKey(serializedKeyData) since `theirIdentityKeyData` doesn't
        // have a type byte.
        let theirIdentityKey = try ECPublicKey(keyData: theirIdentityKeyData)

        // ECKeyPair ephemeral = Curve.generateKeyPair();
        let ephemeral = Curve25519.generateKeyPair()

        // byte[] ephemeralSalt       = ByteUtil.combine("UnidentifiedDelivery".getBytes(), theirIdentity.serialize(), ephemeral.getPublicKey().serialize());
        guard let prefixData = kUDPrefixString.data(using: String.Encoding.utf8) else {
            throw SMKError.assertionError(description: "\(logTag) Could not encode prefix.")
        }
        let ephemeralSalt = NSData.join([
            prefixData,
            theirIdentityKey.serialized,
            try ephemeral.ecPublicKey().serialized
        ])

        // EphemeralKeys ephemeralKeys = calculateEphemeralKeys(theirIdentity, ephemeral.getPrivateKey(), ephemeralSalt);
        let ephemeralKeys = try throwswrapped_calculateEphemeralKeys(ephemeralPublicKey: theirIdentityKey,
                                                                     ephemeralPrivateKey: ephemeral.ecPrivateKey(),
                                                                     salt: ephemeralSalt)

        // byte[] staticKeyCiphertext = encrypt(ephemeralKeys.cipherKey, ephemeralKeys.macKey, ourIdentity.getPublicKey().getPublicKey().serialize());
        let staticKeyCipherData = try encrypt(cipherKey: ephemeralKeys.cipherKey,
                                              macKey: ephemeralKeys.macKey,
                                              plaintextData: ourIdentityKeyPair.ecPublicKey().serialized)

        // byte[] staticSalt = ByteUtil.combine(ephemeralKeys.chainKey, staticKeyCiphertext);
        let staticSalt = NSData.join([
            ephemeralKeys.chainKey,
            staticKeyCipherData
        ])

        // StaticKeys staticKeys = calculateStaticKeys(theirIdentity, ourIdentity.getPrivateKey(), staticSalt);
        let staticKeys = try throwswrapped_calculateStaticKeys(staticPublicKey: theirIdentityKey,
                                                               staticPrivateKey: ourIdentityKeyPair.ecPrivateKey(),
                                                               salt: staticSalt)

        // UnidentifiedSenderMessageContent content = new UnidentifiedSenderMessageContent(message.getType(), senderCertificate, message.serialize());
        var messageType: SMKMessageType
        switch encryptedMessage.cipherMessageType {
        case .prekey:
            messageType = .prekey
        case .whisper:
            messageType = .whisper
        default:
            throw SMKError.assertionError(description: "\(logTag) Unknown cipher message type.")
        }
        guard let encryptedMessageData = encryptedMessage.serialized() else {
            throw SMKError.assertionError(description: "\(logTag) Could not serialize encrypted message.")
        }
        let messageContent = try SMKUnidentifiedSenderMessageContent(messageType: messageType,
                                                                     senderCertificate: senderCertificate,
                                                                     contentData: encryptedMessageData)

        // byte[] messageBytes = encrypt(staticKeys.cipherKey, staticKeys.macKey, content.getSerialized());
        let messageData = try encrypt(cipherKey: staticKeys.cipherKey,
                                      macKey: staticKeys.macKey,
                                      plaintextData: messageContent.serializedData)

        // return new UnidentifiedSenderMessage(ephemeral.getPublicKey(), staticKeyCiphertext, messageBytes).getSerialized();
        let message = try SMKUnidentifiedSenderMessage(ephemeralKey: try ephemeral.ecPublicKey(),
                                                       encryptedStatic: staticKeyCipherData,
                                                       encryptedMessage: messageData)
        return message.serializedData
    }

    // public Pair<SignalProtocolAddress, byte[]> decrypt(CertificateValidator validator, byte[] ciphertext, long timestamp)
    //    throws InvalidMetadataMessageException, InvalidMetadataVersionException, ProtocolInvalidMessageException, ProtocolInvalidKeyException, ProtocolNoSessionException, ProtocolLegacyMessageException, ProtocolInvalidVersionException, ProtocolDuplicateMessageException, ProtocolInvalidKeyIdException, ProtocolUntrustedIdentityException
    @objc
    public func throwswrapped_decryptMessage(certificateValidator: SMKCertificateValidator,
                                          cipherTextData: Data,
                                          timestamp: UInt64,
                                          localE164: String?,
                                          localUuid: UUID?,
                                          localDeviceId: Int32,
                                          protocolContext: SPKProtocolWriteContext?) throws -> SMKDecryptResult {
        guard timestamp > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid timestamp")
        }

        // IdentityKeyPair ourIdentity = signalProtocolStore.getIdentityKeyPair();
        let localAddress = try SMKAddress(uuid: localUuid, e164: localE164)
        guard let ourIdentityKeyPair = identityStore.identityKeyPair(protocolContext) else {
            throw SMKError.assertionError(description: "\(logTag) Missing our identity key pair.")
        }

        // UnidentifiedSenderMessage wrapper = new UnidentifiedSenderMessage(ciphertext);
        let wrapper = try SMKUnidentifiedSenderMessage(serializedData: cipherTextData)

        // byte[] ephemeralSalt = ByteUtil.combine("UnidentifiedDelivery".getBytes(), ourIdentity.getPublicKey().getPublicKey().serialize(), wrapper.getEphemeral().serialize());
        guard let prefixData = kUDPrefixString.data(using: String.Encoding.utf8) else {
            throw SMKError.assertionError(description: "\(logTag) Could not encode prefix.")
        }
        let ephemeralSalt = NSData.join([
            prefixData,
            try ourIdentityKeyPair.ecPublicKey().serialized,
            wrapper.ephemeralKey.serialized
        ])

        // EphemeralKeys ephemeralKeys = calculateEphemeralKeys(wrapper.getEphemeral(), ourIdentity.getPrivateKey(), ephemeralSalt);
        let ephemeralKeys = try throwswrapped_calculateEphemeralKeys(ephemeralPublicKey: wrapper.ephemeralKey,
                                                                     ephemeralPrivateKey: ourIdentityKeyPair.ecPrivateKey(),
                                                                     salt: ephemeralSalt)

        // byte[] staticKeyBytes = decrypt(ephemeralKeys.cipherKey, ephemeralKeys.macKey, wrapper.getEncryptedStatic());
        let staticKeyBytes = try decrypt(cipherKey: ephemeralKeys.cipherKey,
                                         macKey: ephemeralKeys.macKey,
                                         cipherTextWithMac: wrapper.encryptedStatic)

        // ECPublicKey staticKey = Curve.decodePoint(staticKeyBytes, 0);
        let staticKey = try ECPublicKey(serializedKeyData: staticKeyBytes)

        // byte[] staticSalt = ByteUtil.combine(ephemeralKeys.chainKey, wrapper.getEncryptedStatic());
        let staticSalt = NSData.join([ephemeralKeys.chainKey, wrapper.encryptedStatic])

        // StaticKeys staticKeys = calculateStaticKeys(staticKey, ourIdentity.getPrivateKey(), staticSalt);
        let staticKeys = try throwswrapped_calculateStaticKeys(staticPublicKey: staticKey,
                                                               staticPrivateKey: ourIdentityKeyPair.ecPrivateKey(),
                                                               salt: staticSalt)

        // byte[] messageBytes = decrypt(staticKeys.cipherKey, staticKeys.macKey, wrapper.getEncryptedMessage());
        let messageBytes = try decrypt(cipherKey: staticKeys.cipherKey,
                                       macKey: staticKeys.macKey,
                                       cipherTextWithMac: wrapper.encryptedMessage)

        // content = new UnidentifiedSenderMessageContent(messageBytes);
        let messageContent = try SMKUnidentifiedSenderMessageContent(serializedData: messageBytes)

        let senderAddress = messageContent.senderCertificate.senderAddress
        let senderDeviceId = messageContent.senderCertificate.senderDeviceId

        guard !senderAddress.matches(localAddress) || senderDeviceId != localDeviceId else {
            Logger.info("Discarding self-sent message")
            throw SMKSecretSessionCipherError.selfSentMessage
        }

        // validator.validate(content.getSenderCertificate(), timestamp);

        let wrapAsKnownSenderError = { (underlyingError: Error) in
            return SecretSessionKnownSenderError(senderAddress: senderAddress, senderDeviceId: senderDeviceId, underlyingError: underlyingError)
        }

        do {
            try certificateValidator.throwswrapped_validate(senderCertificate: messageContent.senderCertificate,
                                                            validationTime: timestamp)
        } catch {
            throw wrapAsKnownSenderError(error)
        }

        // if (!MessageDigest.isEqual(content.getSenderCertificate().getKey().serialize(), staticKeyBytes)) {
        //   throw new InvalidKeyException("Sender's certificate key does not match key used in message");
        // }
        //
        // NOTE: Constant time comparison.
        guard messageContent.senderCertificate.key.serialized.ows_constantTimeIsEqual(to: staticKeyBytes) else {
            let underlyingError = SMKError.assertionError(description: "\(logTag) Sender's certificate key does not match key used in message.")
            throw wrapAsKnownSenderError(underlyingError)
        }

        let paddedMessagePlaintext: Data
        do {
             paddedMessagePlaintext = try throwswrapped_decrypt(messageContent: messageContent, protocolContext: protocolContext)
        } catch {
            throw wrapAsKnownSenderError(error)
        }

        // return new Pair<>(new SignalProtocolAddress(content.getSenderCertificate().getSender(),
        //     content.getSenderCertificate().getSenderDeviceId()),
        //     decrypt(content));
        //
        // NOTE: We use the sender properties from the sender certificate, not from this class' properties.
        guard senderDeviceId >= 0 && senderDeviceId <= INT_MAX else {
            let underlyingError = SMKError.assertionError(description: "\(logTag) Invalid senderDeviceId.")
            throw wrapAsKnownSenderError(underlyingError)
        }
        return SMKDecryptResult(senderAddress: senderAddress,
                                senderDeviceId: Int(senderDeviceId),
                                paddedPayload: paddedMessagePlaintext,
                                messageType: messageContent.messageType)
    }

    // MARK: - Encrypt

    // private EphemeralKeys calculateEphemeralKeys(ECPublicKey ephemeralPublic, ECPrivateKey ephemeralPrivate, byte[] salt)
    // throws InvalidKeyException {
    private func throwswrapped_calculateEphemeralKeys(ephemeralPublicKey: ECPublicKey,
                                                   ephemeralPrivateKey: ECPrivateKey,
                                                   salt: Data) throws -> SMKEphemeralKeys {
        guard ephemeralPublicKey.keyData.count > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid ephemeralPublicKey")
        }
        guard ephemeralPrivateKey.keyData.count > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid ephemeralPrivateKey")
        }
        guard salt.count > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid salt")
        }

        // byte[] ephemeralSecret = Curve.calculateAgreement(ephemeralPublic, ephemeralPrivate);
        //
        // See:
        // https://github.com/signalapp/libsignal-protocol-java/blob/master/java/src/main/java/org/whispersystems/libsignal/ecc/Curve.java#L30
        let ephemeralSecret = try Curve25519.generateSharedSecret(fromPublicKey: ephemeralPublicKey.keyData, privateKey: ephemeralPrivateKey.keyData)

        // byte[]   ephemeralDerived = new HKDFv3().deriveSecrets(ephemeralSecret, salt, new byte[0], 96);
        let kEphemeralDerivedLength: UInt = 96
        let ephemeralDerived: Data =
            try HKDFKit.deriveKey(ephemeralSecret, info: Data(), salt: salt, outputSize: Int32(kEphemeralDerivedLength))
        guard ephemeralDerived.count == kEphemeralDerivedLength else {
            throw SMKError.assertionError(description: "\(logTag) derived ephemeral has unexpected length: \(ephemeralDerived.count).")
        }

        let ephemeralDerivedParser = OWSDataParser(data: ephemeralDerived)
        let chainKey = try ephemeralDerivedParser.nextData(length: 32, name: "chain key")
        let cipherKey = try ephemeralDerivedParser.nextData(length: 32, name: "cipher key")
        let macKey = try ephemeralDerivedParser.nextData(length: 32, name: "mac key")
        guard ephemeralDerivedParser.isEmpty else {
            throw SMKError.assertionError(description: "\(logTag) could not parse derived ephemeral.")
        }

        return SMKEphemeralKeys(chainKey: chainKey, cipherKey: cipherKey, macKey: macKey)
    }

    // private StaticKeys calculateStaticKeys(ECPublicKey staticPublic, ECPrivateKey staticPrivate, byte[] salt) throws
    // InvalidKeyException {
    private func throwswrapped_calculateStaticKeys(staticPublicKey: ECPublicKey,
                                                staticPrivateKey: ECPrivateKey,
                                                salt: Data) throws -> SMKStaticKeys {
        guard staticPublicKey.keyData.count > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid staticPublicKey")
        }
        guard staticPrivateKey.keyData.count > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid staticPrivateKey")
        }
        guard salt.count > 0 else {
            throw SMKError.assertionError(description: "\(logTag) invalid salt")
        }

        // byte[] staticSecret = Curve.calculateAgreement(staticPublic, staticPrivate);
        //
        // See:
        // https://github.com/signalapp/libsignal-protocol-java/blob/master/java/src/main/java/org/whispersystems/libsignal/ecc/Curve.java#L30
        let staticSecret = try Curve25519.generateSharedSecret(fromPublicKey: staticPublicKey.keyData, privateKey: staticPrivateKey.keyData)

        // byte[] staticDerived = new HKDFv3().deriveSecrets(staticSecret, salt, new byte[0], 96);
        let kStaticDerivedLength: UInt = 96
        let staticDerived: Data =
            try HKDFKit.deriveKey(staticSecret, info: Data(), salt: salt, outputSize: Int32(kStaticDerivedLength))
        guard staticDerived.count == kStaticDerivedLength else {
            throw SMKError.assertionError(description: "\(logTag) could not derive static.")
        }

        // byte[][] staticDerivedParts = ByteUtil.split(staticDerived, 32, 32, 32);
        let staticDerivedParser = OWSDataParser(data: staticDerived)
        // NOTE: javalib doesn't use the first 32 bytes.
        _ = try staticDerivedParser.nextData(length: 32)
        let cipherKey = try staticDerivedParser.nextData(length: 32)
        let macKey = try staticDerivedParser.nextData(length: 32)
        guard staticDerivedParser.isEmpty else {
            throw SMKError.assertionError(description: "\(logTag) invalid derived static.")
        }

        // return new StaticKeys(staticDerivedParts[1], staticDerivedParts[2]);
        return SMKStaticKeys(cipherKey: cipherKey, macKey: macKey)
    }

    // private byte[] encrypt(SecretKeySpec cipherKey, SecretKeySpec macKey, byte[] plaintext) {
    private func encrypt(cipherKey: SMKSecretKeySpec,
                         macKey: SMKSecretKeySpec,
                         plaintextData: Data) throws -> Data {

        // Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
        // cipher.init(Cipher.ENCRYPT_MODE, cipherKey, new IvParameterSpec(new byte[16]));
        // byte[] ciphertext = cipher.doFinal(plaintext);
        guard let aesKey = OWSAES256Key(data: cipherKey.keyData) else {
            throw SMKError.assertionError(description: "\(logTag) Invalid encryption key.")
        }

        // NOTE: The IV is all zeroes.  This is fine since we're using a unique key.
        let initializationVector = Data(count: Int(kAES256CTR_IVLength))

        guard let encryptionResult = Cryptography.encryptAESCTR(plaintextData: plaintextData, initializationVector: initializationVector, key: aesKey) else {
            throw SMKError.assertionError(description: "\(logTag) Could not encrypt data.")
        }
        let cipherText = encryptionResult.ciphertext

        // Mac mac = Mac.getInstance("HmacSHA256");
        // mac.init(macKey);
        //
        // byte[] ourFullMac = mac.doFinal(ciphertext);
        // byte[] ourMac = ByteUtil.trim(ourFullMac, 10);
        guard let ourMac = Cryptography.truncatedSHA256HMAC(cipherText, withHMACKey: macKey.keyData, truncation: 10) else {
            throw SMKError.assertionError(description: "\(logTag) Could not compute HmacSHA256.")
        }

        // return ByteUtil.combine(ciphertext, ourMac);
        let result = NSData.join([cipherText, ourMac])

        return result
    }

    var accountIdFinder: SMKAccountIdFinder {
        return SMKEnvironment.shared.accountIdFinder
    }

    // MARK: - Decrypt

    // private byte[] decrypt(UnidentifiedSenderMessageContent message)
    // throws InvalidVersionException, InvalidMessageException, InvalidKeyException, DuplicateMessageException,
    // InvalidKeyIdException, UntrustedIdentityException, LegacyMessageException, NoSessionException
    private func throwswrapped_decrypt(messageContent: SMKUnidentifiedSenderMessageContent,
                                       protocolContext: SPKProtocolWriteContext?) throws -> Data {

        // SignalProtocolAddress sender = new SignalProtocolAddress(message.getSenderCertificate().getSender(),
        // message.getSenderCertificate().getSenderDeviceId());
        //
        // NOTE: We use the sender properties from the sender certificate, not from this class' properties.
        let senderAddress = messageContent.senderCertificate.senderAddress
        let senderDeviceId = messageContent.senderCertificate.senderDeviceId
        guard senderDeviceId >= 0 && senderDeviceId <= INT32_MAX else {
            throw SMKError.assertionError(description: "\(logTag) Invalid senderDeviceId.")
        }

        // switch (message.getType()) {
        // case CiphertextMessage.WHISPER_TYPE: return new SessionCipher(signalProtocolStore, sender).decrypt(new
        // SignalMessage(message.getContent())); case CiphertextMessage.PREKEY_TYPE: return new
        // SessionCipher(signalProtocolStore, sender).decrypt(new PreKeySignalMessage(message.getContent())); default: throw
        // new InvalidMessageException("Unknown type: " + message.getType());
        // }
        var cipherMessage: CipherMessage
        switch (messageContent.messageType) {
        case .whisper:
            cipherMessage = try WhisperMessage(data: messageContent.contentData)
        case .prekey:
            cipherMessage = try PreKeyWhisperMessage(data: messageContent.contentData)
        }

        guard let accountId = accountIdFinder.accountId(forUuid: senderAddress.uuid, phoneNumber: senderAddress.e164, protocolContext: protocolContext) else {
            throw SMKError.assertionError(description: "\(logTag) accountId was unexpectedly nil")
        }

        let cipher = SessionCipher(sessionStore: sessionStore,
                                   preKeyStore: preKeyStore,
                                   signedPreKeyStore: signedPreKeyStore,
                                   identityKeyStore: identityStore,
                                   recipientId: accountId,
                                   deviceId: Int32(senderDeviceId))

        let plaintextData = try cipher.decrypt(cipherMessage, protocolContext: protocolContext)
        return plaintextData
    }

    // private byte[] decrypt(SecretKeySpec cipherKey, SecretKeySpec macKey, byte[] ciphertext) throws InvalidMacException {
    private func decrypt(cipherKey: SMKSecretKeySpec,
                         macKey: SMKSecretKeySpec,
                         cipherTextWithMac: Data) throws -> Data {

        // if (ciphertext.count < 10) {
        // throw new InvalidMacException("Ciphertext not long enough for MAC!");
        // }
        if (cipherTextWithMac.count < kSMKSecretSessionCipherMacLength) {
            throw SMKError.assertionError(description: "\(logTag) Cipher text not long enough for MAC.")
        }

        // byte[][] ciphertextParts = ByteUtil.split(ciphertext, ciphertext.count - 10, 10);
        let cipherTextWithMacParser = OWSDataParser(data: cipherTextWithMac)
        let cipherTextLength = UInt(cipherTextWithMac.count) - kSMKSecretSessionCipherMacLength
        let cipherText = try cipherTextWithMacParser.nextData(length: cipherTextLength, name: "cipher text")
        let theirMac = try cipherTextWithMacParser.nextData(length: kSMKSecretSessionCipherMacLength, name: "their mac")
        guard cipherTextWithMacParser.isEmpty else {
            throw SMKError.assertionError(description: "\(logTag) Could not parse cipher text.")
        }

        // Mac mac = Mac.getInstance("HmacSHA256");
        // mac.init(macKey);
        //
        // byte[] digest = mac.doFinal(ciphertextParts[0]);
        guard let ourFullMac = Cryptography.computeSHA256HMAC(cipherText, withHMACKey: macKey.keyData) else {
            throw SMKError.assertionError(description: "\(logTag) Could not compute HmacSHA256.")
        }

        // byte[] ourMac = ByteUtil.trim(digest, 10);
        guard ourFullMac.count >= kSMKSecretSessionCipherMacLength else {
            throw SMKError.assertionError(description: "\(logTag) HmacSHA256 has unexpected length.")
        }
        let ourMac = ourFullMac[0..<kSMKSecretSessionCipherMacLength]

        // if (!MessageDigest.isEqual(ourMac, theirMac)) {
        // throw new InvalidMacException("Bad mac!");
        // }
        //
        // NOTE: Constant time comparison.
        guard ourMac.ows_constantTimeIsEqual(to: theirMac) else {
            throw SMKError.assertionError(description: "\(logTag) macs do not match.")
        }

        // Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
        // cipher.init(Cipher.DECRYPT_MODE, cipherKey, new IvParameterSpec(new byte[16]));
        guard let aesKey = OWSAES256Key(data: cipherKey.keyData) else {
            throw SMKError.assertionError(description: "\(logTag) could not parse AES256 key.")
        }

        // NOTE: The IV is all zeroes.  This is fine since we're using a unique key.
        let initializationVector = Data(count: Int(kAES256CTR_IVLength))

        guard let plaintext = Cryptography.decryptAESCTR(cipherText: cipherText, initializationVector: initializationVector, key: aesKey) else {
            throw SMKError.assertionError(description: "\(logTag) could not decrypt AESGCM.")
        }

        return plaintext
    }
}
