//
//  Curve25519.h
//
//  Created by Frederic Jacobs on 22/07/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ECCKeyLength 32
#define ECCSignatureLength 64

@interface ECKeyPair : NSObject <NSSecureCoding> {
    uint8_t publicKey [ECCKeyLength];
    uint8_t privateKey[ECCKeyLength];
}

-(NSData*) publicKey;

@end

@interface Curve25519 : NSObject

/**
 *  Generate a 32-byte shared secret from a public key and a key pair using curve25519.
 *
 *  @param theirPublicKey public curve25519 key
 *  @param keyPair        curve25519 key pair
 *
 *  @return 32-byte shared secret derived from ECDH with curve25519 public key and key pair.
 */

+ (NSData*)generateSharedSecretFromPublicKey:(NSData*)theirPublicKey andKeyPair:(ECKeyPair*)keyPair;

/**
 *  Generate a curve25519 key pair
 *
 *  @return curve25519 key pair.
 */

+ (ECKeyPair*)generateKeyPair;

@end
