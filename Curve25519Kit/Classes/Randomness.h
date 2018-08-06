//
//  Randomness.h
//  AxolotlKit
//
//  Created by Frederic Jacobs on 21/07/14.
//  Copyright (c) 2014 Frederic Jacobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Randomness : NSObject

/**
 *  Generates a given number of cryptographically secure bytes using SecRandomCopyBytes.
 *
 *  @param numberBytes The number of bytes to be generated.
 *
 *  @return Random Bytes.
 */

+(NSData*) generateRandomBytes:(int)numberBytes;


@end
