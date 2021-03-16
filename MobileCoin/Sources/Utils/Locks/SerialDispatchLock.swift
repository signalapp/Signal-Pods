//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// `SerialDispatchLock` is a DispatchQueue-based exclusive lock that wraps data and guards access
/// to it, such that there is only 1 block with access to the contained data executing at any point
/// in time.
///
/// `SerialDispatchLock` uses a serial `DispatchQueue` and uses `DispatchQueue.async` to control
/// access to the data. The serial nature of the queue guarantees there is at most 1 thread with
/// access to the data at any one point in time Because the target queue can be set to an arbitrary
/// queue, only `async` access is provided. This is a safety measure to help avoid the possibility
/// of deadlock.
///
/// The lock is held for the duration of the block that is passed to `accessAsync`. The blocks are
/// executed in the order that the `accessAsync` method is called.
final class SerialDispatchLock<Value> {
    private var value: Value

    let serialExclusionQueue: DispatchQueue

    init(_ value: Value, targetQueue: DispatchQueue?) {
        self.value = value
        self.serialExclusionQueue = DispatchQueue(
            label: "com.mobilecoin.\(Self.self)",
            target: targetQueue)
    }

    init(_ value: Value, serialExclusionQueue: DispatchQueue) {
        self.value = value
        self.serialExclusionQueue = serialExclusionQueue
    }

    var accessWithoutLocking: Value {
        value
    }

    func accessAsync(_ block: @escaping (inout Value) -> Void) {
        serialExclusionQueue.async {
            block(&self.value)
        }
    }

    func mapLockWithoutLocking<T>(
        _ transform: (Value) throws -> T
    ) rethrows -> SerialDispatchLock<T> {
        SerialDispatchLock<T>(try transform(value), serialExclusionQueue: serialExclusionQueue)
    }

}
