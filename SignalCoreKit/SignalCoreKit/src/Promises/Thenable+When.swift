//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

// MARK: - Fulfilled

public extension Thenable {
    static func when<T: Thenable>(fulfilled thenables: [T]) -> Promise<[Value]> where T.Value == Value {
        _when(fulfilled: thenables).map { thenables.compactMap { $0.value } }
    }

    static func when<T: Thenable, U: Thenable>(fulfilled tt: T, _ tu: U) -> Promise<(T.Value, U.Value)> where T.Value == Value {
        Guarantee<Any>._when(fulfilled: [
            AnyPromise(tt), AnyPromise(tu)
        ]).map { (tt.value!, tu.value!) }
    }

    static func when<T: Thenable, U: Thenable, V: Thenable>(fulfilled tt: T, _ tu: U, _ tv: V) -> Promise<(T.Value, U.Value, V.Value)> where T.Value == Value {
        Guarantee<Any>._when(fulfilled: [
            AnyPromise(tt), AnyPromise(tu), AnyPromise(tv)
        ]).map { (tt.value!, tu.value!, tv.value!) }
    }

    static func when<T: Thenable, U: Thenable, V: Thenable, W: Thenable>(fulfilled tt: T, _ tu: U, _ tv: V, _ tw: W) -> Promise<(T.Value, U.Value, V.Value, W.Value)> where T.Value == Value {
        Guarantee<Any>._when(fulfilled: [
            AnyPromise(tt), AnyPromise(tu), AnyPromise(tv), AnyPromise(tw)
        ]).map { (tt.value!, tu.value!, tv.value!, tw.value!) }
    }
}

public extension Thenable where Value == Void {
    static func when<T: Thenable>(fulfilled thenables: T...) -> Promise<Void> {
        _when(fulfilled: thenables)
    }

    static func when<T: Thenable>(fulfilled thenables: [T]) -> Promise<Void> {
        _when(fulfilled: thenables)
    }
}

fileprivate extension Thenable {
    static func _when<T: Thenable>(fulfilled thenables: [T]) -> Promise<Void> {
        guard !thenables.isEmpty else { return Promise.value(()) }

        var pendingPromiseCount = thenables.count

        let (returnPromise, future) = Promise<Void>.pending()

        let lock = UnfairLock()

        for thenable in thenables {
            thenable.observe(on: nil) { result in
                lock.withLock {
                    switch result {
                    case .success:
                        guard !future.isSealed else { return }
                        pendingPromiseCount -= 1
                        if pendingPromiseCount == 0 { future.resolve() }
                    case .failure(let error):
                        guard !future.isSealed else { return }
                        future.reject(error)
                    }
                }
            }
        }

        return returnPromise
    }
}

// MARK: - Resolved

public extension Thenable {
    static func when<T: Thenable>(resolved thenables: T...) -> Guarantee<[Result<Value, Error>]> where T.Value == Value {
        when(resolved: thenables)
    }

    static func when<T: Thenable>(resolved thenables: [T]) -> Guarantee<[Result<Value, Error>]> where T.Value == Value {
        _when(resolved: thenables).map { thenables.compactMap { $0.result } }
    }
}

public extension Thenable where Value == Void {

}

fileprivate extension Thenable {
    static func _when<T: Thenable>(resolved thenables: [T]) -> Guarantee<Void> {
        guard !thenables.isEmpty else { return Guarantee.value(()) }

        var pendingPromiseCount = thenables.count

        let (returnGuarantee, future) = Guarantee<Void>.pending()

        let lock = UnfairLock()

        for thenable in thenables {
            thenable.observe(on: nil) { _ in
                lock.withLock {
                    pendingPromiseCount -= 1
                    if pendingPromiseCount == 0 { future.resolve() }
                }
            }
        }

        return returnGuarantee
    }
}
