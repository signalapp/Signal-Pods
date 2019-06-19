//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Ed25519.h"
#import "Curve25519.h"
#import <SignalCoreKit/OWSAsserts.h>
#import <SignalCoreKit/SCKExceptionWrapper.h>

NS_ASSUME_NONNULL_BEGIN

extern int curve25519_verify(const unsigned char *signature, /* 64 bytes */
    const unsigned char *curve25519_pubkey, /* 32 bytes */
    const unsigned char *msg,
    const unsigned long msg_len);

@interface ECKeyPair ()

- (NSData *)throws_sign:(NSData *)data;

@end

#pragma mark -

@implementation Ed25519

+ (nullable NSData *)sign:(NSData *)data withKeyPair:(ECKeyPair *)keyPair error:(NSError **)outError
{
    @try {
        return [self throws_sign:data withKeyPair:keyPair];
    } @catch (NSException *exception) {
        *outError = SCKExceptionWrapperErrorMake(exception);
        return nil;
    }
}

+ (NSData *)throws_sign:(NSData *)data withKeyPair:(ECKeyPair *)keyPair
{
    if ([data length] < 1) {
        OWSRaiseException(NSInvalidArgumentException, @"Data needs to be at least one byte");
    }
    if (!keyPair) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing key pair.");
    }

    return [keyPair throws_sign:data];
}

+ (BOOL)verifySignature:(NSData *)signature
              publicKey:(NSData *)publicKey
                   data:(NSData *)data
              didVerify:(BOOL *)didVerify
                  error:(NSError **)outError;
{
    @try {
        *didVerify = [self throws_verifySignature:signature publicKey:publicKey data:data];
        // TODO this seems potentially unintuitive for the caller.
        // Instead of returning YES, should we remove didVerify and return an error when verification fails? (but no
        // exception was thrown)
        return YES;
    } @catch (NSException *exception) {
        *outError = SCKExceptionWrapperErrorMake(exception);
        return NO;
    }
}

+ (BOOL)throws_verifySignature:(NSData *)signature publicKey:(NSData *)pubKey data:(NSData *)data
{
    if ([data length] < 1) {
        OWSRaiseException(NSInvalidArgumentException, @"Data needs to be at least one byte");
    }
    if ([data length] >= ULONG_MAX) {
        OWSRaiseException(NSInvalidArgumentException, @"Data is too long.");
    }

    if ([pubKey length] != ECCKeyLength) {
        OWSRaiseException(
            NSInvalidArgumentException, @"Public Key has unexpected length: %lu", (unsigned long)pubKey.length);
    }

    if ([signature length] != ECCSignatureLength) {
        OWSRaiseException(
            NSInvalidArgumentException, @"Signature has unexpected length: %lu", (unsigned long)signature.length);
    }

    BOOL success = (curve25519_verify([signature bytes], [pubKey bytes], [data bytes], [data length]) == 0);
    return success;
}

@end

NS_ASSUME_NONNULL_END
