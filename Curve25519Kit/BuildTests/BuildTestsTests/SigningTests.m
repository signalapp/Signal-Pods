//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Curve25519.h"
#import "Ed25519.h"
#import <SignalCoreKit/Randomness.h>
#import <XCTest/XCTest.h>

@interface SigningTests : XCTestCase

@end

@implementation SigningTests

- (void)setUp
{
    [super setUp];
    
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testingRandom{
    for (int i = 1; i < 1000; i++) {
        for (int j = 0; j < 3; j++) {
            
            ECKeyPair *key = [Curve25519 generateKeyPair];
            
            NSData *data = [Randomness generateRandomBytes:i];

            NSData *signature = [Ed25519 throws_sign:data withKeyPair:key];

            if (![Ed25519 throws_verifySignature:signature publicKey:[key publicKey] data:data]) {
                XCTAssert(false, @"Failed to verify signature while performing testing");
                return;
            }
        }
    }
}

- (void)testingIdentityKeyStyle{
    for (int i = 0; i < 10000; i++) {
        
        ECKeyPair *key = [Curve25519 generateKeyPair];
        
        NSData *data = [Randomness generateRandomBytes:32];

        NSData *signature = [Ed25519 throws_sign:data withKeyPair:key];

        if (![Ed25519 throws_verifySignature:signature publicKey:[key publicKey] data:data]) {
            XCTAssert(false, @"Verifying a signed 32-byte identity key failed");
            return;
        }
    }
}

@end
