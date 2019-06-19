//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

 NS_ASSUME_NONNULL_BEGIN

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
+ (NSData *)throws_sign:(NSData *)data withKeyPair:(ECKeyPair *)keyPair NS_SWIFT_UNAVAILABLE("throws objc exceptions");
+ (nullable NSData *)sign:(NSData *)data withKeyPair:(ECKeyPair *)keyPair error:(NSError **)outError;

/**
 *  Verify ed25519 signature with 32-bytes Curve25519 key pair. Throws an NSInvalid
 *
 *  @param signature ed25519 64-byte signature.
 *  @param publicKey public key of the signer.
 *  @param data      data to be checked against the signature.
 *
 *  @return Returns TRUE if the signature is valid, false if it's not.
 */
+ (BOOL)throws_verifySignature:(NSData *)signature
                  publicKey:(NSData *)publicKey
                       data:(NSData *)data NS_SWIFT_UNAVAILABLE("throws objc exceptions");

/**
 *  Verify ed25519 signature with 32-bytes Curve25519 key pair. Throws an NSInvalid
 *
 *  @param signature ed25519 64-byte signature.
 *  @param publicKey public key of the signer.
 *  @param data      data to be checked against the signature.
 *  @param didVerify whether or not the signature was verified.
 *
 *  @return Returns YES if no error was encountered
 *          Returns NO if an error was encountered while verifying signature.
 *
 *  NOTE: In line with convention's required for Swift interop, the return value does *not* indicate
 *  whether or not the signature was verified - check `didVerify` for that. The return value only
 *  indicates whether an error was encountered.
 */
+ (BOOL)verifySignature:(NSData *)signature
              publicKey:(NSData *)publicKey
                   data:(NSData *)data
              didVerify:(BOOL *)didVerify
                  error:(NSError **)outError NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
