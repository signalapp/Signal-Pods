//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger kAES256_KeyByteLength;
extern const NSUInteger kAESGCM256_DefaultIVLength;
extern const NSUInteger kAES256CTR_IVLength;

/// Key appropriate for use in AES256-GCM
@interface OWSAES256Key : NSObject <NSSecureCoding>

/// Generates new secure random key
- (instancetype)init;
+ (instancetype)generateRandomKey;

/**
 * @param data  representing the raw key bytes
 *
 * @returns a new instance if key is of appropriate length for AES256-GCM
 *          else returns nil.
 */
+ (nullable instancetype)keyWithData:(NSData *)data;

/// The raw key material
@property (nonatomic, readonly) NSData *keyData;

@end

#pragma mark -

// TODO: This class should probably be renamed to: AES256GCMEncryptionResult
// (note the missing 6 in 256).
@interface AES25GCMEncryptionResult : NSObject

@property (nonatomic, readonly) NSData *ciphertext;
@property (nonatomic, readonly) NSData *initializationVector;
@property (nonatomic, readonly) NSData *authTag;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCipherText:(NSData *)cipherText
                       initializationVector:(NSData *)initializationVector
                                    authTag:(NSData *)authTag NS_DESIGNATED_INITIALIZER;

@end

#pragma mark -

@interface AES256CTREncryptionResult : NSObject

@property (nonatomic, readonly) NSData *ciphertext;
@property (nonatomic, readonly) NSData *initializationVector;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCiphertext:(NSData *)ciphertext
                       initializationVector:(NSData *)initializationVector NS_DESIGNATED_INITIALIZER;

@end

#pragma mark -

@interface Cryptography : NSObject

typedef NS_ENUM(NSInteger, TSMACType) {
    TSHMACSHA256Truncated10Bytes = 2,
    TSHMACSHA256AttachementType  = 3
};

+ (NSData *)generateRandomBytes:(NSUInteger)numberBytes;

+ (uint32_t)randomUInt32;
+ (uint64_t)randomUInt64;
+ (unsigned)randomUnsigned;

#pragma mark - AES-GCM

+ (nullable AES25GCMEncryptionResult *)encryptAESGCMWithData:(NSData *)plaintext
                                  initializationVectorLength:(NSUInteger)initializationVectorLength
                                 additionalAuthenticatedData:(nullable NSData *)additionalAuthenticatedData
                                                         key:(OWSAES256Key *)key
    NS_SWIFT_NAME(encryptAESGCM(plainTextData:initializationVectorLength:additionalAuthenticatedData:key:));

+ (nullable AES25GCMEncryptionResult *)encryptAESGCMWithData:(NSData *)plaintext
                                        initializationVector:(NSData *)initializationVector
                                 additionalAuthenticatedData:(nullable NSData *)additionalAuthenticatedData
                                                         key:(OWSAES256Key *)key
    NS_SWIFT_NAME(encryptAESGCM(plainTextData:initializationVector:additionalAuthenticatedData:key:));

+ (nullable NSData *)decryptAESGCMWithInitializationVector:(NSData *)initializationVector
                                                ciphertext:(NSData *)ciphertext
                               additionalAuthenticatedData:(nullable NSData *)additionalAuthenticatedData
                                                   authTag:(NSData *)authTagFromEncrypt
                                                       key:(OWSAES256Key *)key
    NS_SWIFT_NAME(decryptAESGCM(withInitializationVector:ciphertext:additionalAuthenticatedData:authTag:key:));

+ (nullable NSData *)encryptAESGCMWithDataAndConcatenateResults:(NSData *)plaintext
                                     initializationVectorLength:(NSUInteger)initializationVectorLength
                                                            key:(OWSAES256Key *)key
    NS_SWIFT_NAME(encryptAESGCMWithDataAndConcatenateResults(plainTextData:initializationVectorLength:key:));

+ (nullable NSData *)decryptAESGCMConcatenatedData:(NSData *)concatenatedData
                        initializationVectorLength:(NSUInteger)initializationVectorLength
                                               key:(OWSAES256Key *)key
    NS_SWIFT_NAME(decryptAESGCMConcatenatedData(encryptedData:initializationVectorLength:key:));

#pragma mark - Profiles

+ (nullable NSData *)encryptAESGCMWithProfileData:(NSData *)plaintextData key:(OWSAES256Key *)key
    NS_SWIFT_NAME(encryptAESGCMProfileData(plainTextData:key:));

+ (nullable NSData *)decryptAESGCMWithProfileData:(NSData *)encryptedData key:(OWSAES256Key *)key
    NS_SWIFT_NAME(decryptAESGCMProfileData(encryptedData:key:));

#pragma mark - AES-CTR

+ (nullable AES256CTREncryptionResult *)encryptAESCTRWithData:(NSData *)plaintext
                                         initializationVector:(NSData *)initializationVector
                                                          key:(OWSAES256Key *)key
    NS_SWIFT_NAME(encryptAESCTR(plaintextData:initializationVector:key:));

+ (nullable NSData *)decryptAESCTRWithCipherText:(NSData *)cipherText
                            initializationVector:(NSData *)initializationVector
                                             key:(OWSAES256Key *)key
    NS_SWIFT_NAME(decryptAESCTR(cipherText:initializationVector:key:));

#pragma mark -

+ (void)seedRandom;

@end

NS_ASSUME_NONNULL_END
