//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// `ReadWriteDispatchLock` is a DispatchQueue-based read-write lock that wraps data and guards
/// access to it, such that at any point in time there is either 1 writer and 0 readers, or there is
/// 0 writers and any number of readers.
///
/// `ReadWriteDispatchLock` uses a concurrent `DispatchQueue` and uses `DispatchQueue.sync` to
/// control access to wrapped data. It uses a barrier `sync` call for write access (so that it has
/// exclusive access) and a non-barrier `sync` call for read access (so multiple threads can access
/// concurrently). Using `sync` rather than `async` ensures that no extra threads are created from
/// use of the queue, since GCD ensures the block is executed on the same thread that made the
/// `sync` call.
///
/// The lock is held for the duration of the block that is passed to `readSync` or `writeSync`. The
/// blocks are executed in the order that the `readSync` and`writeSync` methods are called. Note
/// that this only means they are started in order. They can still finish out of order, depending on
/// how long each block takes to finish.
final class ReadWriteDispatchLock<Value> {
    private var value: Value

    /// Concurrent `DispatchQueue` used as a read-write lock around data we want to have synchronous
    /// access to, `value`. Reads of this data occur within a `sync` block, while writes occur
    /// within a `sync(flags: .barrier)`block. Using `sync` ensures that no extra threads are
    /// created, despite the `DispatchQueue` being concurrent.
    private let concurrentExclusionQueue: DispatchQueue

    init(_ value: Value) {
        self.value = value
        self.concurrentExclusionQueue = DispatchQueue(
            label: "com.mobilecoin.\(Self.self)",
            attributes: .concurrent)
    }

    private init(_ value: Value, concurrentExclusionQueue: DispatchQueue) {
        self.value = value
        self.concurrentExclusionQueue = concurrentExclusionQueue
    }

    var accessWithoutLocking: Value {
        value
    }

    func readSync<T>(_ block: (Value) throws -> T) rethrows -> T {
        try concurrentExclusionQueue.sync {
            try block(value)
        }
    }

    func writeSync<T>(_ block: (inout Value) throws -> T) rethrows -> T {
        try concurrentExclusionQueue.sync(flags: .barrier) {
            try block(&value)
        }
    }

    func mapLock<T>(_ transform: (Value) throws -> T) rethrows -> ReadWriteDispatchLock<T> {
        try concurrentExclusionQueue.sync {
            ReadWriteDispatchLock<T>(
                try transform(value),
                concurrentExclusionQueue: concurrentExclusionQueue)
        }
    }

    func mapLockWithoutLocking<T>(
        _ transform: (Value) throws -> T
    ) rethrows -> ReadWriteDispatchLock<T> {
        ReadWriteDispatchLock<T>(
            try transform(value),
            concurrentExclusionQueue: concurrentExclusionQueue)
    }
}
