//
//  NBMetadataHelper.h
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"

@class NBPhoneMetaData;

@interface NBMetadataHelper : NSObject

+ (BOOL)hasValue:(NSString *)string;

- (instancetype)init;

- (NSArray *)regionCodeFromCountryCode:(NSNumber *)countryCodeNumber;
- (NSString *)countryCodeFromRegionCode:(NSString *)regionCode;

- (NBPhoneMetaData *)getMetadataForNonGeographicalRegion:(NSNumber *)countryCallingCode;
- (NBPhoneMetaData *)getMetadataForRegion:(NSString *)regionCode;

- (NSDictionary *)countryCodeToCountryNumberDictionary;
- (NSArray *)getAllMetadata;

@end
