//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

// The block is executed immediately if called from the
// main thread; otherwise it is dispatched async to the
// main thread.
void DispatchMainThreadSafe(dispatch_block_t block);

// The block is executed immediately if called from the
// main thread; otherwise it is dispatched sync to the
// main thread.
void DispatchSyncMainThreadSafe(dispatch_block_t block);

/// Returns YES if the result returned from dispatch_get_current_queue() matches
/// the provided queue. There's all sorts of different circumstances where these queue
/// comparisons may fail (queue hierarchies, etc.) so this should only be used optimistically
/// for perf optimizations. This should never be used to determine if some pattern of block dispatch is deadlock free.
BOOL DispatchQueueIsCurrentQueue(dispatch_queue_t queue);

NS_ASSUME_NONNULL_END
