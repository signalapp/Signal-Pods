//
//  Ed25519.h
//
//  Created by Frederic Jacobs on 22/07/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECKeyPair;

@interface Ed25519 : NSObject

/**
 *  ed25519 signature of a message with a curve25519 key pair.
 *
 *  @param data    data to be signed
 *  @param keyPair curve25519 32-byte key pair.
 *
 *  @return The ed25519 64-bytes signature.
 */

+(NSData*)sign:(NSData*)data withKeyPair:(ECKeyPair*)keyPair;

/**
 *  Verify ed25519 signature with 32-bytes Curve25519 key pair. Throws an NSInvalid
 *
 *  @param signature ed25519 64-byte signature.
 *  @param pubKey    public key of the signer.
 *  @param data      data to be checked against the signature.
 *
 *  @return Returns TRUE if the signature is valid, false if it's not.
 */

+(BOOL)verifySignature:(NSData*)signature publicKey:(NSData*)pubKey data:(NSData*)data;

@end
