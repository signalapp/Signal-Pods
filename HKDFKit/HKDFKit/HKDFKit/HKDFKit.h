//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HKDFKit : NSObject

/**
 *  Standard HKDF implementation. http://tools.ietf.org/html/rfc5869
 *
 *  @param seed       Original keying material
 *  @param info       Expansion "salt"
 *  @param salt       Extraction salt
 *  @param outputSize Size of the output
 *
 *  @return The derived key material
 */
+ (NSData *)throws_deriveKey:(NSData *)seed
                        info:(nullable NSData *)info
                        salt:(NSData *)salt
                  outputSize:(int)outputSize NS_SWIFT_UNAVAILABLE("throws objc exceptions");
+ (nullable NSData *)deriveKey:(NSData *)seed
                          info:(nullable NSData *)info
                          salt:(NSData *)salt
                    outputSize:(int)outputSize
                         error:(NSError **)outError;

/**
 *  TextSecure v2 HKDF implementation
 *
 *  @param seed       Original keying material
 *  @param info       Expansion "salt"
 *  @param salt       Extraction salt
 *  @param outputSize Size of the output
 *
 *  @return The derived key material
 */
+ (NSData *)throws_TextSecureV2deriveKey:(NSData *)seed
                                    info:(nullable NSData *)info
                                    salt:(NSData *)salt
                              outputSize:(int)outputSize NS_SWIFT_UNAVAILABLE("throws objc exceptions");

@end

NS_ASSUME_NONNULL_END
