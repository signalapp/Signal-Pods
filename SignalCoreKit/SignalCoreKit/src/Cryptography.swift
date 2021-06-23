//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation
import CommonCrypto

public extension Cryptography {
    class func pbkdf2Derivation(password: Data, salt: Data, iterations: UInt32, outputLength: Int) -> Data? {
        guard password.count > 0 else {
            owsFailDebug("Invalid password.")
            return nil
        }

        guard salt.count > 0 else {
            owsFailDebug("Invalid salt.")
            return nil
        }

        guard iterations > 0 else {
            owsFailDebug("Invalid iterations.")
            return nil
        }

        guard outputLength > 0 else {
            owsFailDebug("Invalid outputLength.")
            return nil
        }

        let passwordBytes: [Int8] = password.withUnsafeBytes {
            [Int8]($0.bindMemory(to: Int8.self))
        }
        let saltBytes: [UInt8] = salt.withUnsafeBytes { [UInt8]($0) }
        var outputBytes = [UInt8](repeating: 0, count: outputLength)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes,
            passwordBytes.count,
            saltBytes,
            saltBytes.count,
            CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
            iterations,
            &outputBytes,
            outputBytes.count
        )

        guard status == noErr else {
            owsFailDebug("Unexpected status: \(status)")
            return nil
        }

        return Data(outputBytes)
    }

    // MARK: - HMAC-SIV

    private static let hmacsivIVLength = 16
    private static let hmacsivDataLength = 32

    private class func invalidLengthError(_ parameter: String) -> Error {
        return OWSAssertionError("\(parameter) length is invalid")
    }

    /// Encrypts a 32-byte `data` with the provided 32-byte `key` using SHA-256 HMAC-SIV.
    /// Returns a tuple of (16-byte IV, 32-byte Ciphertext) or `nil` if an error occurs.
    class func encryptSHA256HMACSIV(data: Data, key: Data) throws -> (iv: Data, ciphertext: Data) {
        guard data.count == hmacsivDataLength else { throw invalidLengthError("data") }
        guard key.count == hmacsivDataLength else { throw invalidLengthError("key") }

        guard let authData = "auth".data(using: .utf8),
            let Ka = computeSHA256HMAC(authData, key: key) else {
                throw OWSAssertionError("failed to compute Ka")
        }
        guard let encData = "enc".data(using: .utf8),
            let Ke = computeSHA256HMAC(encData, key: key) else {
                throw OWSAssertionError("failed to compute Ke")
        }

        guard let iv = computeSHA256HMAC(data, key: Ka, truncatedToBytes: UInt(hmacsivIVLength)) else {
            throw OWSAssertionError("failed to compute IV")
        }

        guard let Kx = computeSHA256HMAC(iv, key: Ke) else {
            throw OWSAssertionError("failed to compute Kx")
        }

        let ciphertext = try Kx ^ data

        return (iv, ciphertext)
    }

    /// Decrypts a 32-byte `cipherText` with the provided 32-byte `key` and 16-byte `iv` using SHA-256 HMAC-SIV.
    /// Returns the decrypted 32-bytes of data or `nil` if an error occurs.
    class func decryptSHA256HMACSIV(iv: Data, cipherText: Data, key: Data) throws -> Data {
        guard iv.count == hmacsivIVLength else { throw invalidLengthError("iv") }
        guard cipherText.count == hmacsivDataLength else { throw invalidLengthError("cipherText") }
        guard key.count == hmacsivDataLength else { throw invalidLengthError("key") }

        guard let authData = "auth".data(using: .utf8),
            let Ka = computeSHA256HMAC(authData, key: key) else {
                throw OWSAssertionError("failed to compute Ka")
        }
        guard let encData = "enc".data(using: .utf8),
            let Ke = computeSHA256HMAC(encData, key: key) else {
                throw OWSAssertionError("failed to compute Ke")
        }

        guard let Kx = computeSHA256HMAC(iv, key: Ke) else {
            throw OWSAssertionError("failed to compute Kx")
        }

        let decryptedData = try Kx ^ cipherText

        guard let ourIV = computeSHA256HMAC(decryptedData, key: Ka, truncatedToBytes: UInt(hmacsivIVLength)) else {
            throw OWSAssertionError("failed to compute IV")
        }

        guard ourIV.ows_constantTimeIsEqual(to: iv) else {
            throw OWSAssertionError("failed to validate IV")
        }

        return decryptedData
    }

    // SHA-256

    /// Generates the SHA256 digest for a file.
    @objc
    class func computeSHA256DigestOfFile(at url: URL) throws -> Data {
        let file = try FileHandle(forReadingFrom: url)
        var digestContext = SHA256DigestContext()
        try file.enumerateInBlocks { try digestContext.update($0) }
        return try digestContext.finalize()
    }

    @objc
    class func computeSHA256Digest(_ data: Data) -> Data? {
        var digestContext = SHA256DigestContext()
        do {
            try digestContext.update(data)
            return try digestContext.finalize()
        } catch {
            owsFailDebug("Failed to compute digest \(error)")
            return nil
        }
    }

    @objc
    class func computeSHA256Digest(_ data: Data, truncatedToBytes: UInt) -> Data? {
        guard let digest = computeSHA256Digest(data), digest.count >= truncatedToBytes else { return nil }
        return digest.subdata(in: digest.startIndex..<digest.startIndex.advanced(by: Int(truncatedToBytes)))
    }

    @objc
    class func computeSHA256HMAC(_ data: Data, key: Data) -> Data? {
        do {
            var context = try HmacContext(key: key)
            try context.update(data)
            return try context.finalize()
        } catch {
            owsFailDebug("Failed to compute hmac \(error)")
            return nil
        }
    }

    @objc
    class func computeSHA256HMAC(_ data: Data, key: Data, truncatedToBytes: UInt) -> Data? {
        guard let hmac = computeSHA256HMAC(data, key: key), hmac.count >= truncatedToBytes else { return nil }
        return hmac.subdata(in: hmac.startIndex..<hmac.startIndex.advanced(by: Int(truncatedToBytes)))
    }
}

extension Data {
    static func ^(lhs: Data, rhs: Data) throws -> Data {
        guard lhs.count == rhs.count else { throw OWSAssertionError("lhs length must equal rhs length") }
        return Data(zip(lhs, rhs).map { $0 ^ $1 })
    }
}

// MARK: - Attachments

public struct EncryptionMetadata {
    public let key: Data
    public let digest: Data?
    public let length: Int?
    public let plaintextLength: Int?

    public init(key: Data, digest: Data? = nil, length: Int? = nil, plaintextLength: Int? = nil) {
        self.key = key
        self.digest = digest
        self.length = length
        self.plaintextLength = plaintextLength
    }
}

public extension Cryptography {

    fileprivate static let hmac256KeyLength = 32
    fileprivate static let hmac256OutputLength = 32
    fileprivate static let aescbcIVLength = 16
    fileprivate static let aesKeySize = 32

    class func paddedSize(unpaddedSize: UInt) -> UInt {
        // In order to obsfucate attachment size on the wire, we round up
        // attachement plaintext bytes to the nearest power of 1.05. This
        // number was selected as it provides a good balance between number
        // of buckets and wasted bytes on the wire.
        return UInt(max(541, floor(pow(1.05, ceil(log(Double(unpaddedSize)) / log(1.05))))))
    }

    class func encryptAttachment(at unencryptedUrl: URL, output encryptedUrl: URL) throws -> EncryptionMetadata {
        guard FileManager.default.fileExists(atPath: unencryptedUrl.path) else {
            throw OWSAssertionError("Missing attachment file.")
        }

        let inputFile = try FileHandle(forReadingFrom: unencryptedUrl)

        guard FileManager.default.createFile(
            atPath: encryptedUrl.path,
            contents: nil,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        ) else {
            throw OWSAssertionError("Cannot access output file.")
        }
        let outputFile = try FileHandle(forWritingTo: encryptedUrl)

        let iv = generateRandomBytes(UInt(aescbcIVLength))
        let encryptionKey = generateRandomBytes(UInt(aesKeySize))
        let hmacKey = generateRandomBytes(UInt(hmac256KeyLength))

        var hmacContext = try HmacContext(key: hmacKey)
        var digestContext = SHA256DigestContext()
        var cipherContext = try CipherContext(
            operation: .encrypt,
            algorithm: .aes,
            options: .pkcs7Padding,
            key: encryptionKey,
            iv: iv
        )

        // We include our IV at the start of the file *and*
        // in both the hmac and digest.
        try hmacContext.update(iv)
        try digestContext.update(iv)
        outputFile.write(iv)

        let unpaddedPlaintextLength: UInt

        // Encrypt the file by enumerating blocks. We want to keep our
        // memory footprint as small as possible during encryption.
        do {
            try inputFile.enumerateInBlocks { plaintextDataBlock in
                let ciphertextBlock = try cipherContext.update(plaintextDataBlock)

                try hmacContext.update(ciphertextBlock)
                try digestContext.update(ciphertextBlock)
                outputFile.write(ciphertextBlock)
            }

            // Add zero padding to the plaintext attachment data if necessary.
            unpaddedPlaintextLength = UInt(inputFile.offsetInFile)
            let paddedPlaintextLength = paddedSize(unpaddedSize: unpaddedPlaintextLength)
            if paddedPlaintextLength > unpaddedPlaintextLength {
                let ciphertextBlock = try cipherContext.update(
                    Data(repeating: 0, count: Int(paddedPlaintextLength - unpaddedPlaintextLength))
                )

                try hmacContext.update(ciphertextBlock)
                try digestContext.update(ciphertextBlock)
                outputFile.write(ciphertextBlock)
            }

            // Finalize the encryption and write out the last block.
            // Every time we "update" the cipher context, it returns
            // the ciphertext for the previous block so there will
            // always be one block remaining when we "finalize".
            let finalCiphertextBlock = try cipherContext.finalize()

            try hmacContext.update(finalCiphertextBlock)
            try digestContext.update(finalCiphertextBlock)
            outputFile.write(finalCiphertextBlock)
        }

        // Calculate our HMAC. This will be used to verify the
        // data after decryption.
        // hmac of: iv || encrypted data
        let hmac = try hmacContext.finalize()

        // We write the hmac at the end of the file for the
        // receiver to use for verification. We also include
        // it in the digest.
        try digestContext.update(hmac)
        outputFile.write(hmac)

        // Calculate our digest. This will be used to verify
        // the data after decryption.
        // digest of: iv || encrypted data || hmac
        let digest = try digestContext.finalize()

        return EncryptionMetadata(
            key: encryptionKey + hmacKey,
            digest: digest,
            length: Int(outputFile.offsetInFile),
            plaintextLength: Int(unpaddedPlaintextLength)
        )
    }

    class func decryptAttachment(
        at encryptedUrl: URL,
        metadata: EncryptionMetadata,
        output unencryptedUrl: URL
    ) throws {
        // We require digests for all attachments.
        guard let digest = metadata.digest, !digest.isEmpty else {
            throw OWSAssertionError("Missing digest")
        }
        try decryptFile(at: encryptedUrl, metadata: metadata, output: unencryptedUrl)
    }

    class func decryptFile(
        at encryptedUrl: URL,
        metadata: EncryptionMetadata,
        output unencryptedUrl: URL
    ) throws {
        guard FileManager.default.fileExists(atPath: encryptedUrl.path) else {
            throw OWSAssertionError("Missing attachment file.")
        }

        guard let encryptedLength = try encryptedUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              encryptedLength >= (aescbcIVLength + hmac256OutputLength) else {
            throw OWSAssertionError("Encrypted file shorter than crypto overhead")
        }

        let plaintextLength: UInt64?
        if let length = metadata.plaintextLength, length > 0 {
            plaintextLength = UInt64(length)
        } else {
            plaintextLength = nil
        }

        guard metadata.key.count == (aesKeySize + hmac256KeyLength) else {
            throw OWSAssertionError("Encryption key shorter than combined key length")
        }

        let inputFile = try FileHandle(forReadingFrom: encryptedUrl)

        guard FileManager.default.createFile(
            atPath: unencryptedUrl.path,
            contents: nil,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        ) else {
            throw OWSAssertionError("Cannot access output file.")
        }
        let outputFile = try FileHandle(forWritingTo: unencryptedUrl)

        // In the event of any failure, we both throw *and*
        // delete the partially decrypted output file.
        func eraseOutputFileAndError(_ description: String) throws -> Error {
            outputFile.closeFile()
            try FileManager.default.removeItem(at: unencryptedUrl)
            return OWSAssertionError(description)
        }

        // This first N bytes of the encrypted file are the IV
        let iv = inputFile.readData(ofLength: Int(aescbcIVLength))
        guard iv.count == aescbcIVLength else {
            throw try eraseOutputFileAndError("Failed to read IV")
        }

        // The metadata "key" is actually a concatentation of the
        // encryption key and the hmac key.
        let encryptionKey = metadata.key.prefix(aesKeySize)
        let hmacKey = metadata.key.suffix(hmac256KeyLength)

        var hmacContext = try HmacContext(key: hmacKey)
        var digestContext = metadata.digest != nil ? SHA256DigestContext() : nil
        var cipherContext = try CipherContext(
            operation: .decrypt,
            algorithm: .aes,
            options: .pkcs7Padding,
            key: encryptionKey,
            iv: iv
        )

        // Matching encryption, we must start our hmac
        // and digest with the IV, since the encrypted
        // file starts with the IV
        try hmacContext.update(iv)
        try digestContext?.update(iv)

        // The last N bytes of the encrypted file is the hmac
        // for the encrypted data.
        let hmacOffset = UInt64(encryptedLength - hmac256OutputLength)
        inputFile.seek(toFileOffset: hmacOffset)
        let theirHmac = inputFile.readData(ofLength: hmac256OutputLength)
        guard theirHmac.count == hmac256OutputLength else {
            throw try eraseOutputFileAndError("Failed to read hmac")
        }

        // Move the file handle to the start of the encrypted data (after IV)
        inputFile.seek(toFileOffset: UInt64(aescbcIVLength))

        // Decrypt the file by enumerating blocks. We want to keep our
        // memory footprint as small as possible during decryption.
        do {
            try inputFile.enumerateInBlocks(maxOffset: hmacOffset) { ciphertextBlock in
                try hmacContext.update(ciphertextBlock)
                try digestContext?.update(ciphertextBlock)

                let plaintextDataBlock = try cipherContext.update(ciphertextBlock)
                outputFile.write(plaintextDataBlock, truncatingAfterOffset: plaintextLength)
            }

            // Finalize the decryption and write out the last block.
            // Every time we "update" the cipher context, it returns
            // the plaintext for the previous block so there will
            // always be one block remaining when we "finalize".
            let plaintextDataBlock = try cipherContext.finalize()
            outputFile.write(plaintextDataBlock, truncatingAfterOffset: plaintextLength)
        }

        // If a plaintext length was specified, validate that we actually
        // received plaintext of that length. Note, some older clients do
        // not tell us about the unpadded plaintext length so we cannot
        // universally check this.
        if let plaintextLength = plaintextLength, plaintextLength != outputFile.offsetInFile {
            throw try eraseOutputFileAndError("Incorrect plaintext length.")
        }

        // Verify their HMAC matches our locally calculated HMAC
        // hmac of: iv || encrypted data
        let hmac = try hmacContext.finalize()
        guard hmac.ows_constantTimeIsEqual(to: theirHmac) else {
            Logger.debug("Bad hmac. Their hmac: \(theirHmac.hexadecimalString), our hmac: \(hmac.hexadecimalString)")
            throw try eraseOutputFileAndError("Bad hmac")
        }

        // Verify their digest matches our locally calculated digest
        // digest of: iv || encrypted data || hmac
        if let theirDigest = metadata.digest {
            guard var digestContext = digestContext else {
                throw try eraseOutputFileAndError("Missing digest context")
            }
            try digestContext.update(hmac)
            let digest = try digestContext.finalize()
            guard digest.ows_constantTimeIsEqual(to: theirDigest) else {
                Logger.debug("Bad digest. Their digest: \(theirDigest.hexadecimalString), our digest: \(digest.hexadecimalString)")
                throw try eraseOutputFileAndError("Bad digest")
            }
        }
    }
}

extension FileHandle {
    func enumerateInBlocks(
        blockSize: Int = 1024 * 1024,
        maxOffset: UInt64? = nil,
        block: (Data) throws -> Void
    ) rethrows {
        // Read up to `bufferSize` bytes, until EOF is reached
        while try autoreleasepool(invoking: {
            var blockSize = blockSize
            var hasReachedMaxOffset = false
            if let maxOffset = maxOffset, (maxOffset - offsetInFile) < blockSize {
                blockSize = Int(maxOffset - offsetInFile)
                hasReachedMaxOffset = true
            }

            let data = self.readData(ofLength: blockSize)
            if data.count > 0 {
                try block(data)
                return !hasReachedMaxOffset // Continue only if we haven't reached the max offset
            } else {
                return false // End of file
            }
        }) { }
    }

    func write(_ data: Data, truncatingAfterOffset maxOffset: UInt64?) {
        if let maxOffset = maxOffset, (offsetInFile + UInt64(data.count)) > maxOffset {
            write(data.prefix(Int(maxOffset - offsetInFile)))
        } else {
            write(data)
        }
    }
}

struct SHA256DigestContext {
    private var context = CC_SHA256_CTX()
    private var isFinal = false

    init() {
        CC_SHA256_Init(&context)
    }

    mutating func update(_ data: Data) throws {
        try data.withUnsafeBytes { try update(bytes: $0) }
    }

    mutating func update(bytes: UnsafeRawBufferPointer) throws {
        guard !isFinal else {
            throw OWSAssertionError("Unexpectedly attempted update a finalized hmac digest")
        }

        CC_SHA256_Update(&context, bytes.baseAddress, numericCast(bytes.count))
    }

    mutating func finalize() throws -> Data {
        guard !isFinal else {
            throw OWSAssertionError("Unexpectedly attempted to finalize a finalized hmac digest")
        }

        isFinal = true

        var digest = Data(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = digest.withUnsafeMutableBytes {
            CC_SHA256_Final($0.baseAddress?.assumingMemoryBound(to: UInt8.self), &context)
        }
        return digest
    }
}

struct HmacContext {
    private var context = CCHmacContext()
    private var isFinal = false

    init(key: Data) throws {
        key.withUnsafeBytes {
            CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), $0.baseAddress, $0.count)
        }
    }

    mutating func update(_ data: Data) throws {
        try data.withUnsafeBytes { try update(bytes: $0) }
    }

    mutating func update(bytes: UnsafeRawBufferPointer) throws {
        guard !isFinal else {
            throw OWSAssertionError("Unexpectedly attempted to update a finalized hmac context")
        }

        CCHmacUpdate(&context, bytes.baseAddress, bytes.count)
    }

    mutating func finalize() throws -> Data {
        guard !isFinal else {
            throw OWSAssertionError("Unexpectedly to finalize a finalized hmac context")
        }

        isFinal = true

        var mac = Data(repeating: 0, count: Cryptography.hmac256OutputLength)
        mac.withUnsafeMutableBytes {
            CCHmacFinal(&context, $0.baseAddress)
        }
        return mac
    }
}

struct CipherContext {
    enum Operation {
        case encrypt
        case decrypt

        var ccValue: CCOperation {
            switch self {
            case .encrypt: return CCOperation(kCCEncrypt)
            case .decrypt: return CCOperation(kCCDecrypt)
            }
        }
    }

    enum Algorithm {
        case aes
        case des
        case threeDes
        case cast
        case rc4
        case rc2
        case blowfish

        var ccValue: CCOperation {
            switch self {
            case .aes: return CCAlgorithm(kCCAlgorithmAES)
            case .des: return CCAlgorithm(kCCAlgorithmDES)
            case .threeDes: return CCAlgorithm(kCCAlgorithm3DES)
            case .cast: return CCAlgorithm(kCCAlgorithmCAST)
            case .rc4: return CCAlgorithm(kCCAlgorithmRC4)
            case .rc2: return CCAlgorithm(kCCAlgorithmRC2)
            case .blowfish: return CCAlgorithm(kCCAlgorithmBlowfish)
            }
        }
    }

    struct Options: OptionSet {
        let rawValue: Int

        static let pkcs7Padding = Options(rawValue: kCCOptionPKCS7Padding)
        static let ecbMode = Options(rawValue: kCCOptionECBMode)
    }

    private var cryptor: CCCryptorRef?

    init(operation: Operation, algorithm: Algorithm, options: Options, key: Data, iv: Data) throws {
        let result = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                CCCryptorCreate(
                    operation.ccValue,
                    algorithm.ccValue,
                    CCOptions(options.rawValue),
                    keyBytes.baseAddress,
                    keyBytes.count,
                    ivBytes.baseAddress,
                    &cryptor
                )
            }
        }
        guard result == CCStatus(kCCSuccess) else {
            throw OWSAssertionError("Invalid arguments provided \(result)")
        }
    }

    mutating func update(_ data: Data) throws -> Data {
        return try data.withUnsafeBytes { try update(bytes: $0) }
    }

    mutating func update(bytes: UnsafeRawBufferPointer) throws -> Data {
        guard let cryptor = cryptor else {
            throw OWSAssertionError("Unexpectedly attempted to update a finalized cipher")
        }

        var outputLength = CCCryptorGetOutputLength(cryptor, bytes.count, true)
        var outputBuffer = Data(repeating: 0, count: outputLength)
        let result = outputBuffer.withUnsafeMutableBytes {
            CCCryptorUpdate(cryptor, bytes.baseAddress, bytes.count, $0.baseAddress, $0.count, &outputLength)
        }
        guard result == CCStatus(kCCSuccess) else {
            throw OWSAssertionError("Unexpected result \(result)")
        }
        outputBuffer.count = outputLength
        return outputBuffer
    }

    mutating func finalize() throws -> Data {
        guard let cryptor = cryptor else {
            throw OWSAssertionError("Unexpectedly attempted to finalize a finalized cipher")
        }

        defer {
            CCCryptorRelease(cryptor)
            self.cryptor = nil
        }

        var outputLength = CCCryptorGetOutputLength(cryptor, 0, true)
        var outputBuffer = Data(repeating: 0, count: outputLength)
        let result = outputBuffer.withUnsafeMutableBytes {
            CCCryptorFinal(cryptor, $0.baseAddress, $0.count, &outputLength)
        }
        guard result == CCStatus(kCCSuccess) else {
            throw OWSAssertionError("Unexpected result \(result)")
        }
        outputBuffer.count = outputLength
        return outputBuffer
    }
}
