//
//  Curve25519.m
//  BuildTests
//
//  Created by Frederic Jacobs on 22/07/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "Curve25519.h"
#import "Randomness.h"

NSString * const TSECKeyPairPublicKey   = @"TSECKeyPairPublicKey";
NSString * const TSECKeyPairPrivateKey  = @"TSECKeyPairPrivateKey";
NSString * const TSECKeyPairPreKeyId    = @"TSECKeyPairPreKeyId";

extern void curve25519_donna(unsigned char *output, const unsigned char *a, const unsigned char *b);

extern int  curve25519_sign(unsigned char* signature_out, /* 64 bytes */
                     const unsigned char* curve25519_privkey, /* 32 bytes */
                     const unsigned char* msg, const unsigned long msg_len,
                     const unsigned char* random); /* 64 bytes */

@implementation ECKeyPair

+ (BOOL)supportsSecureCoding{
    return YES;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBytes:self->publicKey length:ECCKeyLength forKey:TSECKeyPairPublicKey];
    [coder encodeBytes:self->privateKey length:ECCKeyLength forKey:TSECKeyPairPrivateKey];
}

-(id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        NSUInteger returnedLength = 0;
        const uint8_t *returnedBuffer = NULL;
        // De-serialize public key
        returnedBuffer = [coder decodeBytesForKey:TSECKeyPairPublicKey returnedLength:&returnedLength];
        if (returnedLength != ECCKeyLength) {
            return nil;
        }
        memcpy(self->publicKey, returnedBuffer, ECCKeyLength);
        
        // De-serialize private key
        returnedBuffer = [coder decodeBytesForKey:TSECKeyPairPrivateKey returnedLength:&returnedLength];
        if (returnedLength != ECCKeyLength) {
            return nil;
        }
        memcpy(self->privateKey, returnedBuffer, ECCKeyLength);
    }
    return self;
}


+(ECKeyPair*)generateKeyPair{
    ECKeyPair* keyPair =[[ECKeyPair alloc] init];
    
    // Generate key pair as described in https://code.google.com/p/curve25519-donna/
    memcpy(keyPair->privateKey, [[Randomness  generateRandomBytes:32] bytes], 32);
    keyPair->privateKey[0]  &= 248;
    keyPair->privateKey[31] &= 127;
    keyPair->privateKey[31] |= 64;
    
    static const uint8_t basepoint[ECCKeyLength] = {9};
    curve25519_donna(keyPair->publicKey, keyPair->privateKey, basepoint);
    
    return keyPair;
}

-(NSData*) publicKey {
    return [NSData dataWithBytes:self->publicKey length:32];
}

-(NSData*) sign:(NSData*)data{
    Byte signatureBuffer[ECCSignatureLength];
    NSData *randomBytes = [Randomness generateRandomBytes:64];
    
    if(curve25519_sign(signatureBuffer, self->privateKey, [data bytes], [data length], [randomBytes bytes]) == -1 ){
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Message couldn't be signed." userInfo:nil];
    }
    
    NSData *signature = [NSData dataWithBytes:signatureBuffer length:ECCSignatureLength];
    
    return signature;
}

-(NSData*) generateSharedSecretFromPublicKey:(NSData*)theirPublicKey {
    unsigned char *sharedSecret = NULL;
    
    if ([theirPublicKey length] != 32) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"The supplied public key does not contain 32 bytes" userInfo:nil];
    }
    
    sharedSecret = malloc(32);
    
    if (sharedSecret == NULL) {
        free(sharedSecret);
        return nil;
    }
    
    curve25519_donna(sharedSecret,self->privateKey, [theirPublicKey bytes]);
    
    NSData *sharedSecretData = [NSData dataWithBytes:sharedSecret length:32];
    
    free(sharedSecret);
    
    return sharedSecretData;
}

@end

@implementation Curve25519

+(ECKeyPair*)generateKeyPair{
    return [ECKeyPair generateKeyPair];
}

+(NSData*)generateSharedSecretFromPublicKey:(NSData *)theirPublicKey andKeyPair:(ECKeyPair *)keyPair{
    return [keyPair generateSharedSecretFromPublicKey:theirPublicKey];
}

@end
