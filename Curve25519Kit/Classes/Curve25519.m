//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

#import "Curve25519.h"
#import <SignalCoreKit/OWSAsserts.h>
#import <SignalCoreKit/Randomness.h>
#import <SignalCoreKit/SCKExceptionWrapper.h>

NS_ASSUME_NONNULL_BEGIN

extern void curve25519_donna(unsigned char *output, const unsigned char *a, const unsigned char *b);

@interface ECKeyPair (ImplementedInSwift)
+ (Class)concreteSubclass;
- (nullable NSData *)sign:(NSData *)data error:(NSError **)error;
@end

@implementation ECKeyPair

@dynamic publicKey;
@dynamic privateKey;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (Class)classForKeyedUnarchiver
{
    return [self concreteSubclass];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    // FIXME: This should never be called thanks to +classForKeyedUnarchiver above,
    // but there's a test in SignalServiceKit that calls it directly.
    return [[[ECKeyPair concreteSubclass] alloc] initWithCoder:coder];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    OWSFail(@"Implemented by subclass; should never be called directly");
}

/**
 * Build a keypair from existing key data.
 * If you need a *new* keypair, user `generateKeyPair` instead.
 */
- (nullable instancetype)initWithPublicKeyData:(NSData *)publicKeyData
                                privateKeyData:(NSData *)privateKeyData
                                         error:(NSError **)error
{
    return [[[ECKeyPair concreteSubclass] alloc] initWithPublicKeyData:publicKeyData
                                                        privateKeyData:privateKeyData
                                                                 error:error];
}

- (instancetype)initFromClassClusterSubclassOnly
{
    self = [super init];
    return self;
}

+ (ECKeyPair *)generateKeyPair
{
    return [[self concreteSubclass] generateKeyPair];
}

- (NSData *)throws_sign:(NSData *)data
{
    if (!data) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing data.");
    }

    NSError *error;
    NSData *signatureData = [self sign:data error:&error];
    if (!signatureData) {
        OWSRaiseException(NSInternalInconsistencyException, @"Message couldn't be signed: %@", error);
    }

    return signatureData;
}

@end

#pragma mark -

@implementation Curve25519

+ (ECKeyPair *)generateKeyPair
{
    return [ECKeyPair generateKeyPair];
}

+ (NSData *)throws_generateSharedSecretFromPublicKey:(NSData *)theirPublicKey andKeyPair:(ECKeyPair *)keyPair
{
    if (!keyPair) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing key pair.");
    }

    return [self throws_generateSharedSecretFromPublicKey:theirPublicKey privateKey:keyPair.privateKey];
}

+ (nullable NSData *)generateSharedSecretFromPublicKey:(NSData *)publicKey
                                            privateKey:(NSData *)privateKey
                                                 error:(NSError **)outError
{
    @try {
        return [self throws_generateSharedSecretFromPublicKey:publicKey privateKey:privateKey];
    } @catch (NSException *exception) {
        *outError = SCKExceptionWrapperErrorMake(exception);
        return nil;
    }
}

+ (NSData *)throws_generateSharedSecretFromPublicKey:(NSData *)publicKey privateKey:(NSData *)privateKey
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
