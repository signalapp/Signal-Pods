#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Cryptography.h"
#import "iOSVersions.h"
#import "NSData+OWS.h"
#import "NSDate+OWS.h"
#import "NSObject+OWS.h"
#import "NSString+OWS.h"
#import "OWSAsserts.h"
#import "OWSLogs.h"
#import "Randomness.h"
#import "SCKError.h"
#import "SCKExceptionWrapper.h"
#import "SignalCoreKit.h"
#import "Threading.h"

FOUNDATION_EXPORT double SignalCoreKitVersionNumber;
FOUNDATION_EXPORT const unsigned char SignalCoreKitVersionString[];

