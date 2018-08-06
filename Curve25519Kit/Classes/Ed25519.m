//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Ed25519.h"
#import "Curve25519.h"

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
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Data needs to be at least one byte"
                                     userInfo:nil];
    }

    return [keyPair sign:data];
}

+ (BOOL)verifySignature:(NSData *)signature publicKey:(NSData *)pubKey data:(NSData *)data
{

    if ([data length] < 1) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Data needs to be at least one byte"
                                     userInfo:nil];
    }
    if ([data length] >= ULONG_MAX) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Data is too long" userInfo:nil];
    }

    if ([pubKey length] != ECCKeyLength) {
        @throw
            [NSException exceptionWithName:NSInvalidArgumentException reason:@"Public Key isn't 32 bytes" userInfo:nil];
    }

    if ([signature length] != ECCSignatureLength) {
        @throw
            [NSException exceptionWithName:NSInvalidArgumentException reason:@"Signature isn't 64 bytes" userInfo:nil];
    }

    BOOL success = (curve25519_verify([signature bytes], [pubKey bytes], [data bytes], [data length]) == 0);
    return success;
}

@end
