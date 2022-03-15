//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "SCKError.h"
#import <SignalCoreKit/SignalCoreKit-Swift.h>

NSErrorDomain const SCKErrorDomain = @"SignalCoreKitErrorDomain";

NSError *SCKErrorWithCodeDescription(NSUInteger code, NSString *description)
{
    return [NSError errorWithDomain:SCKErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey: description }];
}

NSError *SCKErrorMakeAssertionError(NSString *description, ...) {
    OWSCFailDebug(@"Assertion failed: %@", description);
    return SCKErrorWithCodeDescription(SCKErrorCode_AssertionError,
                                       OWSLocalizedString(@"ERROR_DESCRIPTION_UNKNOWN_ERROR", @"Worst case generic error message"));
}
