//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger kAES256_KeyByteLength;

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

@interface Cryptography : NSObject

typedef NS_ENUM(NSInteger, TSMACType) {
    TSHMACSHA256Truncated10Bytes = 2,
    TSHMACSHA256AttachementType  = 3
};

+ (NSData *)generateRandomBytes:(NSUInteger)numberBytes;

+ (uint32_t)randomUInt32;
+ (uint64_t)randomUInt64;
+ (unsigned)randomUnsigned;

#pragma mark -

+ (void)seedRandom;

@end

NS_ASSUME_NONNULL_END
