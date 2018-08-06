//
//  HKDFKit.m
//  HKDFKit
//
//  Created by Frederic Jacobs on 29/03/14.
//  Copyright (c) 2014 Frederic Jacobs. All rights reserved.
//

#import "HKDFKit.h"
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

#define HKDF_HASH_ALG kCCHmacAlgSHA256
#define HKDF_HASH_LEN CC_SHA256_DIGEST_LENGTH

@implementation HKDFKit

+ (NSData *)deriveKey:(NSData *)seed info:(nullable NSData *)info salt:(NSData *)salt outputSize:(int)outputSize
{
    return [self deriveKey:seed info:info salt:salt outputSize:outputSize offset:1];
}

+ (NSData *)TextSecureV2deriveKey:(NSData *)seed
                             info:(nullable NSData *)info
                             salt:(NSData *)salt
                       outputSize:(int)outputSize
{
    return [self deriveKey:seed info:info salt:salt outputSize:outputSize offset:0];
}

#pragma mark Private Methods

+ (NSData *)deriveKey:(NSData *)seed
                 info:(nullable NSData *)info
                 salt:(NSData *)salt
           outputSize:(int)outputSize
               offset:(int)offset
{
    NSData *prk = [self extract:seed salt:salt];
    NSData *okm = [self expand:prk info:info outputSize:outputSize offset:offset];
    return okm;
}

+ (NSData *)extract:(NSData *)data salt:(NSData *)salt
{
    if (!salt) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Missing salt." userInfo:nil];
    }
    if (salt.length >= SIZE_MAX) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Oversize salt." userInfo:nil];
    }
    if (!data) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Missing data." userInfo:nil];
    }
    if (data.length >= SIZE_MAX) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Oversize data." userInfo:nil];
    }

    NSMutableData *prkData = [[NSMutableData alloc] initWithLength:HKDF_HASH_LEN];
    CCHmac(HKDF_HASH_ALG, [salt bytes], [salt length], [data bytes], [data length], prkData.mutableBytes);
    return [prkData copy];
}

+ (NSData *)expand:(NSData *)data info:(nullable NSData *)info outputSize:(int)outputSize offset:(int)offset
{
    if (!data) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Missing data." userInfo:nil];
    }
    if (data.length >= SIZE_MAX) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Oversize data." userInfo:nil];
    }
    if (info != nil && info.length >= SIZE_MAX) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Oversize info." userInfo:nil];
    }
    if (outputSize >= NSUIntegerMax) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Oversize outputSize." userInfo:nil];
    }
    if (outputSize < 1) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid outputSize." userInfo:nil];
    }

    int iterations = (int)ceil((double)outputSize / (double)HKDF_HASH_LEN);
    NSData *mixin = [NSData data];
    NSMutableData *results = [NSMutableData data];

    for (int i = offset; i < (iterations + offset); i++) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, HKDF_HASH_ALG, [data bytes], [data length]);
        CCHmacUpdate(&ctx, [mixin bytes], [mixin length]);
        if (info != nil) {
            CCHmacUpdate(&ctx, [info bytes], [info length]);
        }
        unsigned char c = i;
        CCHmacUpdate(&ctx, &c, 1);
        NSMutableData *stepResultData = [[NSMutableData alloc] initWithLength:HKDF_HASH_LEN];
        CCHmacFinal(&ctx, stepResultData.mutableBytes);
        [results appendData:stepResultData];
        mixin = [stepResultData copy];
    }

    return [results subdataWithRange:NSMakeRange(0, outputSize)];
}

@end

NS_ASSUME_NONNULL_END
