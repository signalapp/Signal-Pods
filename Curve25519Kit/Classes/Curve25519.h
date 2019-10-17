//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define ECCKeyLength 32
#define ECCSignatureLength 64

extern NSErrorDomain const Curve25519KitErrorDomain;
typedef NS_ERROR_ENUM(Curve25519KitErrorDomain, Curve25519KitError){
    Curve25519KitError_InvalidKeySize = 1
};

@interface ECKeyPair : NSObject <NSSecureCoding>

@property (atomic, readonly) NSData *publicKey;
@property (atomic, readonly) NSData *privateKey;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Build a keypair from existing key data.
 * If you need a *new* keypair, user `Curve25519.generateKeyPair` instead.
 */
- (nullable instancetype)initWithPublicKeyData:(NSData *)publicKeyData
                                privateKeyData:(NSData *)privateKeyData
                                         error:(NSError **)error NS_DESIGNATED_INITIALIZER;

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
+ (NSData *)throws_generateSharedSecretFromPublicKey:(NSData *)theirPublicKey andKeyPair:(ECKeyPair *)keyPair NS_SWIFT_UNAVAILABLE("throws objc expections");

+ (NSData *)throws_generateSharedSecretFromPublicKey:(NSData *)publicKey privateKey:(NSData *)privateKey NS_SWIFT_UNAVAILABLE("throws objc expections");

+ (nullable NSData *)generateSharedSecretFromPublicKey:(NSData *)publicKey
                                   privateKey:(NSData *)privateKey
                                        error:(NSError **)outError;

/**
 *  Generate a curve25519 key pair
 *
 *  @return curve25519 key pair.
 */
+ (ECKeyPair *)generateKeyPair;

@end

NS_ASSUME_NONNULL_END
