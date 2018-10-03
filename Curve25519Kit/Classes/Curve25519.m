//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Curve25519.h"
#import <SignalCoreKit/Randomness.h>
#import <SignalCoreKit/OWSAsserts.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const TSECKeyPairPublicKey = @"TSECKeyPairPublicKey";
NSString *const TSECKeyPairPrivateKey = @"TSECKeyPairPrivateKey";
NSString *const TSECKeyPairPreKeyId = @"TSECKeyPairPreKeyId";

extern void curve25519_donna(unsigned char *output, const unsigned char *a, const unsigned char *b);

extern int curve25519_sign(unsigned char *signature_out, /* 64 bytes */
    const unsigned char *curve25519_privkey, /* 32 bytes */
    const unsigned char *msg,
    const unsigned long msg_len,
    const unsigned char *random); /* 64 bytes */

@implementation ECKeyPair

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBytes:self.publicKey.bytes length:ECCKeyLength forKey:TSECKeyPairPublicKey];
    [coder encodeBytes:self.privateKey.bytes length:ECCKeyLength forKey:TSECKeyPairPrivateKey];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        NSUInteger returnedLength = 0;
        const uint8_t *returnedBuffer = NULL;
        // De-serialize public key
        returnedBuffer = [coder decodeBytesForKey:TSECKeyPairPublicKey returnedLength:&returnedLength];
        if (returnedLength != ECCKeyLength) {
            return nil;
        }
        _publicKey = [NSData dataWithBytes:returnedBuffer length:returnedLength];

        // De-serialize private key
        returnedBuffer = [coder decodeBytesForKey:TSECKeyPairPrivateKey returnedLength:&returnedLength];
        if (returnedLength != ECCKeyLength) {
            return nil;
        }
        _privateKey = [NSData dataWithBytes:returnedBuffer length:returnedLength];
    }
    return self;
}

- (nullable id)initWithPublicKey:(NSData *)publicKey privateKey:(NSData *)privateKey
{
    if (self = [super init]) {
        if (publicKey.length != ECCKeyLength || privateKey.length != ECCKeyLength) {
            return nil;
        }
        _publicKey = publicKey;
        _privateKey = privateKey;
    }
    return self;
}

+ (ECKeyPair *)generateKeyPair
{
    // Generate key pair as described in
    // https://code.google.com/p/curve25519-donna/
    NSMutableData *privateKey = [[Randomness generateRandomBytes:ECCKeyLength] mutableCopy];
    uint8_t *privateKeyBytes = privateKey.mutableBytes;
    privateKeyBytes[0] &= 248;
    privateKeyBytes[31] &= 127;
    privateKeyBytes[31] |= 64;

    static const uint8_t basepoint[ECCKeyLength] = { 9 };

    NSMutableData *publicKey = [NSMutableData dataWithLength:ECCKeyLength];
    if (!publicKey) {
        OWSFail(@"Could not allocate buffer");
    }

    curve25519_donna(publicKey.mutableBytes, privateKey.mutableBytes, basepoint);

    return [[ECKeyPair alloc] initWithPublicKey:[publicKey copy] privateKey:[privateKey copy]];
}

- (NSData *)sign:(NSData *)data
{
    if (!data) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing data.");
    }

    NSMutableData *signatureData = [NSMutableData dataWithLength:ECCSignatureLength];
    if (!signatureData) {
        OWSFail(@"Could not allocate buffer");
    }

    NSData *randomBytes = [Randomness generateRandomBytes:64];

    if (curve25519_sign(
            signatureData.mutableBytes, self.privateKey.bytes, [data bytes], [data length], [randomBytes bytes])
        == -1) {
        OWSRaiseException(NSInternalInconsistencyException, @"Message couldn't be signed.");
    }

    return [signatureData copy];
}

@end

#pragma mark -

@implementation Curve25519

+ (ECKeyPair *)generateKeyPair
{
    return [ECKeyPair generateKeyPair];
}

+ (NSData *)generateSharedSecretFromPublicKey:(NSData *)theirPublicKey andKeyPair:(ECKeyPair *)keyPair
{
    if (!keyPair) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing key pair.");
    }

    return [self generateSharedSecretFromPublicKey:theirPublicKey privateKey:keyPair.privateKey];
}

+ (NSData *)generateSharedSecretFromPublicKey:(NSData *)publicKey privateKey:(NSData *)privateKey
{
    if (publicKey.length != ECCKeyLength) {
        OWSRaiseException(
                          NSInvalidArgumentException, @"Public key has unexpected length: %lu", (unsigned long)publicKey.length);
    }
    if (privateKey.length != ECCKeyLength) {
        OWSRaiseException(
                          NSInvalidArgumentException, @"Private key has unexpected length: %lu", (unsigned long)privateKey.length);
    }

    NSMutableData *sharedSecretData = [NSMutableData dataWithLength:32];
    if (!sharedSecretData) {
        OWSFail(@"Could not allocate buffer");
    }

    curve25519_donna(sharedSecretData.mutableBytes, privateKey.bytes, publicKey.bytes);

    return [sharedSecretData copy];
}

@end

NS_ASSUME_NONNULL_END
