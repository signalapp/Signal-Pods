//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "HKDFKit.h"
#import <CommonCrypto/CommonCrypto.h>
#import <SignalCoreKit/OWSAsserts.h>
#import <SignalCoreKit/SCKExceptionWrapper.h>

NS_ASSUME_NONNULL_BEGIN

#define HKDF_HASH_ALG kCCHmacAlgSHA256
#define HKDF_HASH_LEN CC_SHA256_DIGEST_LENGTH

@implementation HKDFKit

+ (nullable NSData *)deriveKey:(NSData *)seed
                          info:(nullable NSData *)info
                          salt:(NSData *)salt
                    outputSize:(int)outputSize
                         error:(NSError **)outError
{
    @try {
        return [self throws_deriveKey:seed info:info salt:salt outputSize:outputSize];
    } @catch (NSException *exception) {
        *outError = SCKExceptionWrapperErrorMake(exception);
        return nil;
    }
}

+ (NSData *)throws_deriveKey:(NSData *)seed info:(nullable NSData *)info salt:(NSData *)salt outputSize:(int)outputSize
{
    return [self throws_deriveKey:seed info:info salt:salt outputSize:outputSize offset:1];
}

+ (NSData *)throws_TextSecureV2deriveKey:(NSData *)seed
                                    info:(nullable NSData *)info
                                    salt:(NSData *)salt
                              outputSize:(int)outputSize
{
    return [self throws_deriveKey:seed info:info salt:salt outputSize:outputSize offset:0];
}

#pragma mark Private Methods

+ (NSData *)throws_deriveKey:(NSData *)seed
                        info:(nullable NSData *)info
                        salt:(NSData *)salt
                  outputSize:(int)outputSize
                      offset:(int)offset
{
    NSData *prk = [self throws_extract:seed salt:salt];
    NSData *okm = [self throws_expand:prk info:info outputSize:outputSize offset:offset];
    return okm;
}

+ (NSData *)throws_extract:(NSData *)data salt:(NSData *)salt
{
    if (!salt) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing salt.");
    }
    if (salt.length >= SIZE_MAX) {
        OWSRaiseException(NSInvalidArgumentException, @"Oversize salt.");
    }
    if (!data) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing data.");
    }
    if (data.length >= SIZE_MAX) {
        OWSRaiseException(NSInvalidArgumentException, @"Oversize data.");
    }

    NSMutableData *_Nullable prkData = [[NSMutableData alloc] initWithLength:HKDF_HASH_LEN];
    if (!prkData) {
        OWSFail(@"Could not allocate buffer.");
    }
    CCHmac(HKDF_HASH_ALG, [salt bytes], [salt length], [data bytes], [data length], prkData.mutableBytes);
    return [prkData copy];
}

+ (NSData *)throws_expand:(NSData *)data info:(nullable NSData *)info outputSize:(int)outputSize offset:(int)offset
{
    if (!data) {
        OWSRaiseException(NSInvalidArgumentException, @"Missing data.");
    }
    if (data.length >= SIZE_MAX) {
        OWSRaiseException(NSInvalidArgumentException, @"Oversize data.");
    }
    if (info != nil && info.length >= SIZE_MAX) {
        OWSRaiseException(NSInvalidArgumentException, @"Oversize info.");
    }
    if (outputSize >= NSUIntegerMax) {
        OWSRaiseException(NSInvalidArgumentException, @"Oversize outputSize.");
    }
    if (outputSize < 1) {
        OWSRaiseException(NSInvalidArgumentException, @"Invalid outputSize.");
    }

    int iterations = (int)ceil((double)outputSize / (double)HKDF_HASH_LEN);
    NSData *mixin = [NSData data];
    NSMutableData *results = [NSMutableData data];

    NSUInteger generatedLength;
    ows_mul_overflow(HKDF_HASH_LEN, iterations, &generatedLength);

    int offsetIterations;
    ows_add_overflow(iterations, offset, &offsetIterations);

    for (int i = offset; i < offsetIterations; i++) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, HKDF_HASH_ALG, [data bytes], [data length]);
        CCHmacUpdate(&ctx, [mixin bytes], [mixin length]);
        if (info != nil) {
            CCHmacUpdate(&ctx, [info bytes], [info length]);
        }
        unsigned char c = i;
        CCHmacUpdate(&ctx, &c, 1);
        NSMutableData *_Nullable stepResultData = [[NSMutableData alloc] initWithLength:HKDF_HASH_LEN];
        if (!stepResultData) {
            OWSFail(@"Could not allocate buffer.");
        }
        CCHmacFinal(&ctx, stepResultData.mutableBytes);
        [results appendData:stepResultData];
        mixin = [stepResultData copy];
    }
    OWSAssert(results.length == generatedLength);

    return [results subdataWithRange:NSMakeRange(0, outputSize)];
}

@end

NS_ASSUME_NONNULL_END
