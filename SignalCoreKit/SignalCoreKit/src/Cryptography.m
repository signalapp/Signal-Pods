//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "Cryptography.h"
#import "NSData+OWS.h"
#import "SCKError.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import <SignalCoreKit/Randomness.h>
#import <openssl/evp.h>

NS_ASSUME_NONNULL_BEGIN

// Returned by many OpenSSL functions - indicating success
const int kOpenSSLSuccess = 1;

// default length of initialization nonce for AES256-GCM
const NSUInteger kAESGCM256_DefaultIVLength = 12;

const NSUInteger kAES256CTR_IVLength = 16;

// length of authentication tag for AES256-GCM
static const NSUInteger kAESGCM256_TagLength = 16;

const NSUInteger kAES256_KeyByteLength = 32;

@implementation OWSAES256Key

+ (nullable instancetype)keyWithData:(NSData *)data
{
    if (data.length != kAES256_KeyByteLength) {
        OWSLogError(@"Invalid key length: %lu", (unsigned long)data.length);
        return nil;
    }

    return [[self alloc] initWithData:data];
}

+ (instancetype)generateRandomKey
{
    return [self new];
}

- (instancetype)init
{
    return [self initWithData:[Cryptography generateRandomBytes:kAES256_KeyByteLength]];
}

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    _keyData = data;
    
    return self;
}

#pragma mark - SecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    NSData *keyData = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"keyData"];
    if (keyData.length != kAES256_KeyByteLength) {
        OWSFailDebug(@"Invalid key length: %lu", (unsigned long)keyData.length);
        return nil;
    }

    _keyData = keyData;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_keyData forKey:@"keyData"];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OWSAES256Key class]]) {
        OWSAES256Key *otherKey = (OWSAES256Key *)object;
        return [otherKey.keyData ows_constantTimeIsEqualToData:self.keyData];
    }

    return NO;
}

- (NSUInteger)hash
{
    return self.keyData.hash;
}

@end

#pragma mark -

@implementation AES25GCMEncryptionResult

- (nullable instancetype)initWithCipherText:(NSData *)cipherText
                       initializationVector:(NSData *)initializationVector
                                    authTag:(NSData *)authTag
{
    self = [super init];
    if (!self) {
        return self;
    }

    _ciphertext = [cipherText copy];
    _initializationVector = [initializationVector copy];
    _authTag = [authTag copy];

    if (_ciphertext == nil || _initializationVector.length < kAESGCM256_DefaultIVLength
        || _authTag.length != kAESGCM256_TagLength) {
        return nil;
    }

    return self;
}

@end

#pragma mark -

@implementation AES256CTREncryptionResult

- (nullable instancetype)initWithCiphertext:(NSData *)ciphertext initializationVector:(NSData *)initializationVector
{
    self = [super init];
    if (!self) {
        return self;
    }

    _ciphertext = [ciphertext copy];
    _initializationVector = [initializationVector copy];

    if (_ciphertext == nil) {
        OWSFail(@"Missing cipher text.");
        return nil;
    }
    if (_initializationVector.length != kAES256CTR_IVLength) {
        OWSFail(@"Invalid initialization vector.");
        return nil;
    }

    return self;
}

@end

#pragma mark -

@implementation Cryptography

#pragma mark - random bytes methods

+ (NSData *)generateRandomBytes:(NSUInteger)numberBytes
{
    return [Randomness generateRandomBytes:(int)numberBytes];
}

+ (uint32_t)randomUInt32
{
    size_t size = sizeof(uint32_t);
    NSData *data = [self generateRandomBytes:size];
    uint32_t result = 0;
    [data getBytes:&result range:NSMakeRange(0, size)];
    return result;
}

+ (uint64_t)randomUInt64
{
    size_t size = sizeof(uint64_t);
    NSData *data = [self generateRandomBytes:size];
    uint64_t result = 0;
    [data getBytes:&result range:NSMakeRange(0, size)];
    return result;
}

+ (unsigned)randomUnsigned
{
    size_t size = sizeof(unsigned);
    NSData *data = [self generateRandomBytes:size];
    unsigned result = 0;
    [data getBytes:&result range:NSMakeRange(0, size)];
    return result;
}

#pragma mark - AES-GCM

+ (nullable AES25GCMEncryptionResult *)encryptAESGCMWithData:(NSData *)plaintext
                                  initializationVectorLength:(NSUInteger)initializationVectorLength
                                 additionalAuthenticatedData:(nullable NSData *)additionalAuthenticatedData
                                                         key:(OWSAES256Key *)key
{
    OWSAssertDebug(initializationVectorLength >= kAESGCM256_DefaultIVLength);

    NSData *initializationVector = [Cryptography generateRandomBytes:initializationVectorLength];

    return [self encryptAESGCMWithData:plaintext
                  initializationVector:initializationVector
           additionalAuthenticatedData:additionalAuthenticatedData
                                   key:key];
}

+ (nullable AES25GCMEncryptionResult *)encryptAESGCMWithData:(NSData *)plaintext
                                        initializationVector:(NSData *)initializationVector
                                 additionalAuthenticatedData:(nullable NSData *)additionalAuthenticatedData
                                                         key:(OWSAES256Key *)key
{
    OWSAssertDebug(initializationVector.length >= kAESGCM256_DefaultIVLength);

    NSMutableData *ciphertext = [NSMutableData dataWithLength:plaintext.length];
    NSMutableData *authTag = [NSMutableData dataWithLength:kAESGCM256_TagLength];

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        OWSFailDebug(@"failed to build context while encrypting");
        return nil;
    }

    // Initialise the encryption operation.
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to init encryption");
        return nil;
    }

    // Set IV length if default 12 bytes (96 bits) is not appropriate
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)initializationVector.length, NULL) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to set IV length");
        return nil;
    }

    // Initialise key and IV
    if (EVP_EncryptInit_ex(ctx, NULL, NULL, key.keyData.bytes, initializationVector.bytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to set key and iv while encrypting");
        return nil;
    }

    int bytesEncrypted = 0;

    // Provide any AAD data. This can be called zero or more times as
    // required
    if (additionalAuthenticatedData != nil) {
        if (additionalAuthenticatedData.length >= INT_MAX) {
            OWSFailDebug(@"additionalAuthenticatedData too large");
            return nil;
        }
        if (EVP_EncryptUpdate(
                ctx, NULL, &bytesEncrypted, additionalAuthenticatedData.bytes, (int)additionalAuthenticatedData.length)
            != kOpenSSLSuccess) {
            OWSFailDebug(@"encryptUpdate failed");
            return nil;
        }
    }

    if (plaintext.length >= INT_MAX) {
        OWSFailDebug(@"plaintext too large");
        return nil;
    }

    // Provide the message to be encrypted, and obtain the encrypted output.
    //
    // If we wanted to save memory, we could encrypt piece-wise from a plaintext iostream -
    // feeding each chunk to EVP_EncryptUpdate, which can be called multiple times.
    // For simplicity, we currently encrypt the entire plaintext in one shot.
    if (EVP_EncryptUpdate(ctx, ciphertext.mutableBytes, &bytesEncrypted, plaintext.bytes, (int)plaintext.length)
        != kOpenSSLSuccess) {
        OWSFailDebug(@"encryptUpdate failed");
        return nil;
    }
    if (bytesEncrypted != plaintext.length) {
        OWSFailDebug(@"bytesEncrypted != plainTextData.length");
        return nil;
    }

    int finalizedBytes = 0;
    // Finalize the encryption. Normally ciphertext bytes may be written at
    // this stage, but this does not occur in GCM mode
    if (EVP_EncryptFinal_ex(ctx, ciphertext.mutableBytes + bytesEncrypted, &finalizedBytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to finalize encryption");
        return nil;
    }
    if (finalizedBytes != 0) {
        OWSFailDebug(@"Unexpected finalized bytes written");
        return nil;
    }

    // Get the tag
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, kAESGCM256_TagLength, authTag.mutableBytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to write tag");
        return nil;
    }

    // Clean up
    EVP_CIPHER_CTX_free(ctx);

    AES25GCMEncryptionResult *_Nullable result =
        [[AES25GCMEncryptionResult alloc] initWithCipherText:ciphertext
                                        initializationVector:initializationVector
                                                     authTag:authTag];

    return result;
}

+ (nullable NSData *)decryptAESGCMWithInitializationVector:(NSData *)initializationVector
                                                ciphertext:(NSData *)ciphertext
                               additionalAuthenticatedData:(nullable NSData *)additionalAuthenticatedData
                                                   authTag:(NSData *)authTagFromEncrypt
                                                       key:(OWSAES256Key *)key
{
    OWSAssertDebug(initializationVector.length >= kAESGCM256_DefaultIVLength);
    OWSAssertDebug(ciphertext.length > 0);
    OWSAssertDebug(authTagFromEncrypt.length == kAESGCM256_TagLength);
    OWSAssertDebug(key);

    NSMutableData *plaintext = [NSMutableData dataWithLength:ciphertext.length];

    // Create and initialise the context
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();

    if (!ctx) {
        OWSFailDebug(@"failed to build context while decrypting");
        return nil;
    }

    // Initialise the decryption operation.
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to init decryption");
        return nil;
    }

    // Set IV length. Not necessary if this is 12 bytes (96 bits)
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)initializationVector.length, NULL) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to set key and iv while decrypting");
        return nil;
    }

    // Initialise key and IV
    if (EVP_DecryptInit_ex(ctx, NULL, NULL, key.keyData.bytes, initializationVector.bytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"failed to init decryption");
        return nil;
    }

    int decryptedBytes = 0;

    // Provide any AAD data. This can be called zero or more times as
    // required
    if (additionalAuthenticatedData) {
        if (additionalAuthenticatedData.length >= INT_MAX) {
            OWSFailDebug(@"additionalAuthenticatedData too large");
            return nil;
        }
        if (!EVP_DecryptUpdate(ctx,
                NULL,
                &decryptedBytes,
                additionalAuthenticatedData.bytes,
                (int)additionalAuthenticatedData.length)) {
            OWSFailDebug(@"failed during additionalAuthenticatedData");
            return nil;
        }
    }

    // Provide the message to be decrypted, and obtain the plaintext output.
    //
    // If we wanted to save memory, we could decrypt piece-wise from an iostream -
    // feeding each chunk to EVP_DecryptUpdate, which can be called multiple times.
    // For simplicity, we currently decrypt the entire ciphertext in one shot.
    if (ciphertext.length >= INT_MAX) {
        OWSFailDebug(@"ciphertext too large");
        return nil;
    }
    if (EVP_DecryptUpdate(ctx, plaintext.mutableBytes, &decryptedBytes, ciphertext.bytes, (int)ciphertext.length)
        != kOpenSSLSuccess) {
        OWSFailDebug(@"decryptUpdate failed");
        return nil;
    }

    if (decryptedBytes != ciphertext.length) {
        OWSFailDebug(@"Failed to decrypt entire ciphertext");
        return nil;
    }

    // Set expected tag value. Works in OpenSSL 1.0.1d and later
    if (authTagFromEncrypt.length >= INT_MAX) {
        OWSFailDebug(@"authTagFromEncrypt too large");
        return nil;
    }
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, (int)authTagFromEncrypt.length, (void *)authTagFromEncrypt.bytes)
        != kOpenSSLSuccess) {
        OWSFailDebug(@"Failed to set auth tag in decrypt.");
        return nil;
    }

    // Finalise the decryption. A positive return value indicates success,
    // anything else is a failure - the plaintext is not trustworthy.
    int finalBytes = 0;
    int decryptStatus = EVP_DecryptFinal_ex(ctx, (unsigned char *)(plaintext.bytes + decryptedBytes), &finalBytes);

    // AESGCM doesn't write any final bytes
    OWSAssertDebug(finalBytes == 0);

    // Clean up
    EVP_CIPHER_CTX_free(ctx);

    if (decryptStatus > 0) {
        return [plaintext copy];
    } else {
        // This should only happen if the user has changed their profile key, which should only
        // happen currently if they re-register.
        OWSLogError(@"Decrypt verification failed");
        return nil;
    }
}

+ (nullable NSData *)encryptAESGCMWithDataAndConcatenateResults:(NSData *)plaintext
                                     initializationVectorLength:(NSUInteger)initializationVectorLength
                                                            key:(OWSAES256Key *)key
{
    OWSAssertDebug(initializationVectorLength >= kAESGCM256_DefaultIVLength);

    AES25GCMEncryptionResult *result = [self encryptAESGCMWithData:plaintext
                                        initializationVectorLength:initializationVectorLength
                                       additionalAuthenticatedData:nil
                                                               key:key];
    return [NSData join:@[
        result.initializationVector,
        result.ciphertext,
        result.authTag,
    ]];
}

+ (nullable NSData *)decryptAESGCMConcatenatedData:(NSData *)concatenatedData
                        initializationVectorLength:(NSUInteger)initializationVectorLength
                                               key:(OWSAES256Key *)key
{
    OWSAssertDebug(initializationVectorLength >= kAESGCM256_DefaultIVLength);

    NSUInteger cipherTextLength;
    BOOL didOverflow
        = __builtin_sub_overflow(concatenatedData.length, (initializationVectorLength + kAESGCM256_TagLength), &cipherTextLength);
    if (didOverflow) {
        OWSFailDebug(@"unexpectedly short encryptedData.length: %lu", (unsigned long)concatenatedData.length);
        return nil;
    }

    // encryptedData layout: initializationVector || ciphertext || authTag
    NSData *initializationVector = [concatenatedData subdataWithRange:NSMakeRange(0, initializationVectorLength)];
    NSData *ciphertext = [concatenatedData subdataWithRange:NSMakeRange(initializationVectorLength, cipherTextLength)];

    NSUInteger tagOffset;
    ows_add_overflow(initializationVectorLength, cipherTextLength, &tagOffset);

    NSData *authTag = [concatenatedData subdataWithRange:NSMakeRange(tagOffset, kAESGCM256_TagLength)];

    return [self decryptAESGCMWithInitializationVector:initializationVector
                                            ciphertext:ciphertext
                           additionalAuthenticatedData:nil
                                               authTag:authTag
                                                   key:key];
}

#pragma mark - Profiles

+ (nullable NSData *)encryptAESGCMWithProfileData:(NSData *)plaintext key:(OWSAES256Key *)key
{
    return [self encryptAESGCMWithDataAndConcatenateResults:plaintext initializationVectorLength:kAESGCM256_DefaultIVLength key:key];
}

+ (nullable NSData *)decryptAESGCMWithProfileData:(NSData *)encryptedData key:(OWSAES256Key *)key
{
    return [self decryptAESGCMConcatenatedData:encryptedData initializationVectorLength:kAESGCM256_DefaultIVLength key:key];
}

#pragma mark - AES-CTR

+ (nullable AES256CTREncryptionResult *)encryptAESCTRWithData:(NSData *)plaintext
                                         initializationVector:(NSData *)initializationVector
                                                          key:(OWSAES256Key *)key
{
    OWSAssertDebug(plaintext);
    OWSAssertDebug(initializationVector.length == kAES256CTR_IVLength);
    OWSAssertDebug(key);

    NSMutableData *cipherText = [NSMutableData dataWithLength:plaintext.length];

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        OWSFailDebug(@"%@ failed to build context while encrypting", self.logTag);
        return nil;
    }

    // Initialise the encryption operation.
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_ctr(), NULL, NULL, NULL) != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ failed to init encryption", self.logTag);
        return nil;
    }

    // Initialise key and IV
    if (EVP_EncryptInit_ex(ctx, NULL, NULL, key.keyData.bytes, initializationVector.bytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ failed to set key and iv while encrypting", self.logTag);
        return nil;
    }

    if (plaintext.length >= INT_MAX) {
        OWSFailDebug(@"%@ plaintext too large", self.logTag);
        return nil;
    }

    // Provide the message to be encrypted, and obtain the encrypted output.
    //
    // If we wanted to save memory, we could encrypt piece-wise from a plaintext iostream -
    // feeding each chunk to EVP_EncryptUpdate, which can be called multiple times.
    // For simplicity, we currently encrypt the entire plaintext in one shot.
    int bytesEncrypted = 0;
    if (EVP_EncryptUpdate(ctx, cipherText.mutableBytes, &bytesEncrypted, plaintext.bytes, (int)plaintext.length)
        != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ encryptUpdate failed", self.logTag);
        return nil;
    }
    if (bytesEncrypted != plaintext.length) {
        OWSFailDebug(@"%@ bytesEncrypted != plaintextData.length", self.logTag);
        return nil;
    }

    int finalizedBytes = 0;
    // Finalize the encryption. Normally cipherText bytes may be written at
    // this stage, but this does not occur in CTR mode
    if (EVP_EncryptFinal_ex(ctx, cipherText.mutableBytes + bytesEncrypted, &finalizedBytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ failed to finalize encryption", self.logTag);
        return nil;
    }
    if (finalizedBytes != 0) {
        OWSFailDebug(@"%@ Unexpected finalized bytes written", self.logTag);
        return nil;
    }

    // Clean up
    EVP_CIPHER_CTX_free(ctx);

    AES256CTREncryptionResult *_Nullable result =
        [[AES256CTREncryptionResult alloc] initWithCiphertext:cipherText initializationVector:initializationVector];

    return result;
}

+ (nullable NSData *)decryptAESCTRWithCipherText:(NSData *)cipherText
                            initializationVector:(NSData *)initializationVector
                                             key:(OWSAES256Key *)key
{
    OWSAssertDebug(initializationVector.length == kAES256CTR_IVLength);
    OWSAssertDebug(cipherText.length > 0);
    OWSAssertDebug(key);

    NSMutableData *plaintext = [NSMutableData dataWithLength:cipherText.length];

    // Create and initialise the context
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();

    if (!ctx) {
        OWSFailDebug(@"%@ failed to build context while decrypting", self.logTag);
        return nil;
    }

    // Initialise the decryption operation.
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_ctr(), NULL, NULL, NULL) != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ failed to init decryption", self.logTag);
        return nil;
    }

    // Initialise key and IV
    if (EVP_DecryptInit_ex(ctx, NULL, NULL, key.keyData.bytes, initializationVector.bytes) != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ failed to init decryption", self.logTag);
        return nil;
    }

    // Provide the message to be decrypted, and obtain the plaintext output.
    //
    // If we wanted to save memory, we could decrypt piece-wise from an iostream -
    // feeding each chunk to EVP_DecryptUpdate, which can be called multiple times.
    // For simplicity, we currently decrypt the entire cipherText in one shot.
    if (cipherText.length >= INT_MAX) {
        OWSFailDebug(@"%@ cipherText too large", self.logTag);
        return nil;
    }
    int decryptedBytes = 0;
    if (EVP_DecryptUpdate(ctx, plaintext.mutableBytes, &decryptedBytes, cipherText.bytes, (int)cipherText.length)
        != kOpenSSLSuccess) {
        OWSFailDebug(@"%@ decryptUpdate failed", self.logTag);
        return nil;
    }

    if (decryptedBytes != cipherText.length) {
        OWSFailDebug(@"%@ Failed to decrypt entire cipherText", self.logTag);
        return nil;
    }

    // Finalise the decryption. A positive return value indicates success,
    // anything else is a failure - the plaintext is not trustworthy.
    int finalBytes = 0;
    int decryptStatus = EVP_DecryptFinal_ex(ctx, (unsigned char *)(plaintext.bytes + decryptedBytes), &finalBytes);

    // AES CTR doesn't write any final bytes
    OWSAssertDebug(finalBytes == 0);

    // Clean up
    EVP_CIPHER_CTX_free(ctx);

    if (decryptStatus > 0) {
        return [plaintext copy];
    } else {
        DDLogError(@"%@ Decrypt verification failed", self.logTag);
        return nil;
    }
}

#pragma mark -

+ (void)seedRandom
{
    // We should never use rand(), but seed it just in case it's used by 3rd-party code
    unsigned seed = [Cryptography randomUnsigned];
    srand(seed);
}

@end

NS_ASSUME_NONNULL_END
