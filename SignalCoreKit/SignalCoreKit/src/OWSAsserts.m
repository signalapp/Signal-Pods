//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSAsserts.h"
#import <SignalCoreKit/SignalCoreKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

void SwiftExit(NSString *message, const char *file, const char *function, int line)
{
    NSString *_file = [NSString stringWithFormat:@"%s", file];
    NSString *_function = [NSString stringWithFormat:@"%s", function];
    [OWSSwiftUtils owsFail:message file:_file function:_function line:line];
}

void LogStackTrace()
{
    [OWSSwiftUtils logStackTrace];
}

NS_ASSUME_NONNULL_END
