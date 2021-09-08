//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "Threading.h"

NS_ASSUME_NONNULL_BEGIN

void DispatchMainThreadSafe(dispatch_block_t block)
{
    OWSCAssertDebug(block);

    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

void DispatchSyncMainThreadSafe(dispatch_block_t block)
{
    OWSCAssertDebug(block);

    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

BOOL DispatchQueueIsCurrentQueue(dispatch_queue_t testQueue)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    void *currentQueuePtr = (__bridge void *)dispatch_get_current_queue();
#pragma clang diagnostic pop
    return (currentQueuePtr == (__bridge void *)testQueue);
}

NS_ASSUME_NONNULL_END
