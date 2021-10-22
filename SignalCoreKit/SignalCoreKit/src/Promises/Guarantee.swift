//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public final class Guarantee<Value>: Thenable {
    private let future = Future<Value>()
    public var result: Result<Value, Error>? { future.result }
    public var isSealed: Bool { future.isSealed }

    public static func pending() -> (Guarantee<Value>, GuaranteeFuture<Value>) {
        let guarantee = Guarantee<Value>()
        return (guarantee, GuaranteeFuture(future: guarantee.future))
    }

    public init() {}

    public static func value(_ value: Value) -> Self {
        let guarantee = Self()
        guarantee.future.resolve(value)
        return guarantee
    }

    public convenience init(
        _ block: (@escaping (Value) -> Void) -> Void
    ) {
        self.init()
        block { self.future.resolve($0) }
    }

    public convenience init(
        on queue: DispatchQueue,
        _ block: @escaping (@escaping (Value) -> Void) -> Void
    ) {
        self.init()
        queue.asyncIfNecessary { block { self.future.resolve($0) } }
    }

    public func observe(on queue: DispatchQueue? = nil, block: @escaping (Result<Value, Error>) -> Void) {
        future.observe(on: queue, block: block)
    }
}

public extension Guarantee {
    func wait() -> Value {
        var result = future.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            observe(on: .global()) { result = $0; group.leave() }
            group.wait()
        }

        switch result! {
        case .success(let value):
            return value
        case .failure(let error):
            owsFail("Unexpectedly received error result from unfailable promise \(error)")
        }
    }

    func asVoid() -> Guarantee<Void> { map { _ in } }
}

public extension Guarantee {
    func map<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> T
    ) -> Guarantee<T> {
        observe(on: queue, block: block)
    }

    @discardableResult
    func done(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> Void
    ) -> Guarantee<Void> {
        observe(on: queue, block: block)
    }

    @discardableResult
    func then<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> Guarantee<T>
    ) -> Guarantee<T> {
        observe(on: queue, block: block)
    }
}

fileprivate extension Guarantee {
    func observe<T>(
        on queue: DispatchQueue? = nil,
        block: @escaping (Value) -> T
    ) -> Guarantee<T> {
        let (guarantee, future) = Guarantee<T>.pending()
        observe(on: queue) { result in
            switch result {
            case .success(let value):
                future.resolve(block(value))
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return guarantee
    }

    func observe<T>(
        on queue: DispatchQueue? = nil,
        block: @escaping (Value) -> Guarantee<T>
    ) -> Guarantee<T> {
        let (guarantee, future) = Guarantee<T>.pending()
        observe(on: queue) { result in
            switch result {
            case .success(let value):
                future.resolve(on: queue, with: block(value))
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return guarantee
    }
}

public struct GuaranteeFuture<Value> {
    private let future: Future<Value>
    fileprivate init(future: Future<Value>) { self.future = future }
    public var isSealed: Bool { future.isSealed }
    public func resolve(_ value: Value) { future.resolve(value) }
    public func resolve<T: Thenable>(on queue: DispatchQueue? = nil, with thenable: T) where T.Value == Value {
        future.resolve(on: queue, with: thenable)
    }
}

public extension GuaranteeFuture where Value == Void {
    func resolve() { resolve(()) }
}
