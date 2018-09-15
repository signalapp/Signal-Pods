//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Ed25519.h"
#import "Curve25519.h"
#import "SCKAsserts.h"

extern int curve25519_verify(const unsigned char *signature, /* 64 bytes */
    const unsigned char *curve25519_pubkey, /* 32 bytes */
    const unsigned char *msg,
    const unsigned long msg_len);

@interface ECKeyPair ()

- (NSData *)sign:(NSData *)data;

@end

#pragma mark -

@implementation Ed25519

+ (NSData *)sign:(NSData *)data withKeyPair:(ECKeyPair *)keyPair
{

    if ([data length] < 1) {
        OWSRaiseException(NSInvalidArgumentException, @"Data needs to be at least one byte");
    }

    return [keyPair sign:data];
}

+ (BOOL)verifySignature:(NSData *)signature publicKey:(NSData *)pubKey data:(NSData *)data
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
