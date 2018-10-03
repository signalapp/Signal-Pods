//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define ECCKeyLength 32
#define ECCSignatureLength 64

@interface ECKeyPair : NSObject <NSSecureCoding>

@property (atomic, readonly) NSData *publicKey;
@property (atomic, readonly) NSData *privateKey;

- (instancetype)init NS_UNAVAILABLE;

@end

#pragma mark -

@interface Curve25519 : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Generate a 32-byte shared secret from a public key and a key pair using curve25519.
 *
 *  @param theirPublicKey public curve25519 key
 *  @param keyPair        curve25519 key pair
 *
 *  @return 32-byte shared secret derived from ECDH with curve25519 public key and key pair.
 */
+ (NSData *)generateSharedSecretFromPublicKey:(NSData *)theirPublicKey andKeyPair:(ECKeyPair *)keyPair;

+ (NSData *)generateSharedSecretFromPublicKey:(NSData *)publicKey privateKey:(NSData *)privateKey;

/**
 *  Generate a curve25519 key pair
 *
 *  @return curve25519 key pair.
 */
+ (ECKeyPair *)generateKeyPair;

@end

NS_ASSUME_NONNULL_END
