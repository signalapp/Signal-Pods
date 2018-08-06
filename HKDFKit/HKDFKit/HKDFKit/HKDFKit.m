//
//  HKDFKit.m
//  HKDFKit
//
//  Created by Frederic Jacobs on 29/03/14.
//  Copyright (c) 2014 Frederic Jacobs. All rights reserved.
//

#import "HKDFKit.h"
#import <CommonCrypto/CommonCrypto.h>

#define HKDF_HASH_ALG kCCHmacAlgSHA256
#define HKDF_HASH_LEN CC_SHA256_DIGEST_LENGTH

@implementation HKDFKit

+ (NSData *)deriveKey:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(int)outputSize{
    return [self deriveKey:seed info:info salt:salt outputSize:outputSize offset:1];
}

+ (NSData*)TextSecureV2deriveKey:(NSData*)seed info:(NSData*)info salt:(NSData*)salt outputSize:(int)outputSize{
    return [self deriveKey:seed info:info salt:salt outputSize:outputSize offset:0];
}

#pragma mark Private Methods

+ (NSData *)deriveKey:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(int)outputSize offset:(int)offset{
    NSData *prk = [self extract:seed salt:salt];
    NSData *okm = [self expand:prk info:info outputSize:outputSize offset:offset];
    return okm;
}

+ (NSData*)extract:(NSData*)data salt:(NSData*)salt{
    char prk[HKDF_HASH_LEN] = {0};
    CCHmac(HKDF_HASH_ALG, [salt bytes], [salt length], [data bytes], [data length], prk);
    return [NSData dataWithBytes:prk length:sizeof(prk)];
}

+ (NSData*)expand:(NSData*)data info:(NSData*)info outputSize:(int)outputSize offset:(int)offset{
    int             iterations = (int)ceil((double)outputSize/(double)HKDF_HASH_LEN);
    NSData          *mixin = [NSData data];
    NSMutableData   *results = [NSMutableData data];

    for (int i=offset; i<(iterations+offset); i++) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, HKDF_HASH_ALG, [data bytes], [data length]);
        CCHmacUpdate(&ctx, [mixin bytes], [mixin length]);
        if (info != nil) {
            CCHmacUpdate(&ctx, [info bytes], [info length]);
        }
        unsigned char c = i;
        CCHmacUpdate(&ctx, &c, 1);
        unsigned char T[HKDF_HASH_LEN];
        CCHmacFinal(&ctx, T);
        NSData *stepResult = [NSData dataWithBytes:T length:sizeof(T)];
        [results appendData:stepResult];
        mixin = [stepResult copy];
    }
    
    return [[NSData dataWithData:results] subdataWithRange:NSMakeRange(0, outputSize)];
}

@end
