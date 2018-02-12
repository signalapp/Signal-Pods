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

#import "CollapsingFutures.h"
#import "NSArray+TOCFuture.h"
#import "TOCCancelToken+MoreConstructors.h"
#import "TOCCancelTokenAndSource.h"
#import "TOCFuture+MoreContinuations.h"
#import "TOCFuture+MoreContructors.h"
#import "TOCFutureAndSource.h"
#import "TOCTimeout.h"
#import "TOCTypeDefs.h"
#import "TwistedOakCollapsingFutures.h"
#import "TOCInternal.h"
#import "TOCInternal_Array+Functional.h"
#import "TOCInternal_BlockObject.h"
#import "TOCInternal_OnDeallocObject.h"
#import "TOCInternal_Racer.h"

FOUNDATION_EXPORT double TwistedOakCollapsingFuturesVersionNumber;
FOUNDATION_EXPORT const unsigned char TwistedOakCollapsingFuturesVersionString[];

