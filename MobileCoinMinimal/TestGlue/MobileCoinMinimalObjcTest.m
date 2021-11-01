//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "MobileCoinProtosObjcTest.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDTTYLogger.h>

NS_ASSUME_NONNULL_BEGIN

@implementation MobileCoinProtosObjcTest

- (void)setUp
{
    [super setUp];
    
    [DDLog addLogger:DDTTYLogger.sharedInstance];
}

- (void)tearDown
{
    [super tearDown];
}
@end

NS_ASSUME_NONNULL_END
