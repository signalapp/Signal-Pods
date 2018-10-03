//
//  HKDFKitTests.m
//  HKDFKitTests
//
//  Created by Frederic Jacobs on 29/03/14.
//  Copyright (c) 2014 Frederic Jacobs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HKDFKit.h"


@interface HKDFKitTests : XCTestCase

@end

@implementation HKDFKitTests

- (void)setUp
{
    [super setUp];
}

- (void)test1{
    
    NSString *IKM   = @"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b";
    NSString *salt  = @"000102030405060708090a0b0c";
    NSString *info  = @"f0f1f2f3f4f5f6f7f8f9";
    int l           = 42;
    
    NSString *OKM  = @"3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865";
    
    NSData *hkdf = [HKDFKit deriveKey:[self stringToData:IKM] info:[self stringToData:info] salt:[self stringToData:salt] outputSize:l];
    
    XCTAssert([hkdf isEqualToData:[self stringToData:OKM]], @"Basic test case with SHA-256");
    
}

- (void)test2{
    
    NSString *IKM = @"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f";
    NSString *salt = @"606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf";
    NSString *info = @"b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff";
    int l = 82;
    
    NSString *OKM = @"b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87";
    
    NSData *hkdf = [HKDFKit deriveKey:[self stringToData:IKM] info:[self stringToData:info] salt:[self stringToData:salt] outputSize:l];
    
    XCTAssert(([hkdf isEqualToData:[self stringToData:OKM]]), @"Test with SHA-256 and longer inputs/outputs");
    
}

-(void)test3{
    
    NSString *IKM   = @"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b";
    NSData *salt    = [NSData data];
    NSData *info    = [NSData data];
    int l           = 42;
    
    NSString *OKM  = @"8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8";
    
    NSData *hkdf = [HKDFKit deriveKey:[self stringToData:IKM] info:info salt:salt outputSize:l];
    
    XCTAssert(([hkdf isEqualToData:[self stringToData:OKM]]), @"Test with SHA-256 and zero-length salt/info");
    
}

- (void)tearDown
{
    [super tearDown];
}


- (NSData*)stringToData:(NSString*)inputVector{
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [inputVector length]/2; i++) {
        byte_chars[0] = [inputVector characterAtIndex:i*2];
        byte_chars[1] = [inputVector characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return commandToSend;
}

@end
