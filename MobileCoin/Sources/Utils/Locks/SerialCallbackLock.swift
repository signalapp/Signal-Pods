//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// `SerialCallbackLock` is an exclusive lock that wraps data and guards access to it, such that
/// there is only 1 block with access to the contained data executing at any point in time.
///
/// `SerialCallbackLock` is similar to `SerialDispatchLock`, except that `SerialCallbackLock` can be
/// held longer than the duration of the queued block, allowing async tasks to hold the lock until
/// the task is fully complete. This means that the next block requesting the lock is queued until
/// the first task signals that it has completed, rather than when the first task's block finishes.
/// In order to accomplish this, the task is provided with a callback function that it should invoke
/// when the task is complete, which then releases the lock for the next task to acquire.
///
/// Tasks are executed in the order that the `accessAsync` method is called.
final class SerialCallbackLock<Value> {
    private var value: Value

    private let callbackQueue: SerialCallbackQueue

    init(_ value: Value, targetQueue: DispatchQueue?) {
        self.value = value
        self.callbackQueue = SerialCallbackQueue(targetQueue: targetQueue)
    }

    var accessWithoutLocking: Value {
        value
    }

    func accessAsync(_ block: @escaping (inout Value, @escaping () -> Void) -> Void) {
        callbackQueue.append { completion in
            block(&self.value, completion)
        }
    }

    func priorityAccessAsync(_ block: @escaping (inout Value, @escaping () -> Void) -> Void) {
        callbackQueue.prepend { completion in
            block(&self.value, completion)
        }
    }
}

extension SerialCallbackLock {
    func accessAsync(_ block: @escaping (inout Value) -> Void) {
        callbackQueue.append { completion in
            block(&self.value)
            completion()
        }
    }

    func priorityAccessAsync(_ block: @escaping (inout Value) -> Void) {
        callbackQueue.prepend { completion in
            block(&self.value)
            completion()
        }
    }
}

extension SerialCallbackLock {
    func accessAsync<Return>(
        block: @escaping (inout Value, @escaping (Return) -> Void) -> Void,
        completion: @escaping (Return) -> Void
    ) {
        accessAsync { value, callback in
            block(&value) { result in
                callback()
                completion(result)
            }
        }
    }

    func priorityAccessAsync<Return>(
        block: @escaping (inout Value, @escaping (Return) -> Void) -> Void,
        completion: @escaping (Return) -> Void
    ) {
        priorityAccessAsync { value, callback in
            block(&value) { result in
                callback()
                completion(result)
            }
        }
    }
}
