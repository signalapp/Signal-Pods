//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Randomness.h"

@implementation Randomness

+ (NSData *)generateRandomBytes:(int)numberBytes
{
    NSMutableData *_Nullable randomBytes = [NSMutableData dataWithLength:numberBytes];
    if (!randomBytes) {
        @throw [NSException exceptionWithName:@"random problem" reason:@"problem generating the random " userInfo:nil];
    }
    int err = 0;
    err = SecRandomCopyBytes(kSecRandomDefault, numberBytes, [randomBytes mutableBytes]);
    if (err != noErr && randomBytes.length != numberBytes) {
        @throw [NSException exceptionWithName:@"random problem" reason:@"problem generating the random " userInfo:nil];
    }
    return [randomBytes copy];
}

@end
