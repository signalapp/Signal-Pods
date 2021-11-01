//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

/// `ImmutableOnceReadLock` is a Dispatch-based lock that is mutable before being read and immutable
/// afterwards. This is useful in situations where you want to lock in a value and know that it
/// won't change once you start using it, but you still want to freely allow setting it before then.
final class ImmutableOnceReadLock<Value> {
    private let inner: ReadWriteDispatchLock<Inner<Value>>

    // `value` gets locked in place upon first use. Although it's declared `var`, we only ever read
    // it.
    private lazy var value: Value = {
        guard let value = inner.readSync({ $0.get() }) else {
            return inner.writeSync { $0.initializeIfNeededAndGet() }
        }
        return value
    }()

    init(_ value: Value) {
        self.inner = .init(Inner(value))
    }

    /// Gets the contained value and makes it immutable to further changes.
    func get() -> Value {
        // `value` is marked `lazy`, so the first time we read it, the variable initializer is
        // called. All subsequent reads will just read the variable directly. Even though `value` is
        // marked `var`, we don't ever modify it, so we're able to treat it as if it's immutable,
        // and therefore thread-safe.
        value
    }

    /// Sets the contained value if it hasn't been read yet, and returns whether the assignment took
    /// place or not.
    @discardableResult
    func set(_ value: Value) -> Bool {
        inner.writeSync { $0.set(value) }
    }
}

extension ImmutableOnceReadLock {
    private struct Inner<Value> {
        private var value: Value
        private var initialized = false

        init(_ value: Value) {
            self.value = value
        }

        func get() -> Value? {
            guard initialized else {
                return nil
            }
            return value
        }

        mutating func initializeIfNeededAndGet() -> Value {
            if !initialized {
                initialized = true
            }
            return value
        }

        mutating func set(_ value: Value) -> Bool {
            guard !initialized else {
                return false
            }

            initialized = true
            self.value = value

            return true
        }
    }
}
