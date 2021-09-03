//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public protocol Catchable: Thenable {}

public extension Catchable {
    @discardableResult
    func `catch`(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) -> Void
    ) -> Promise<Void> {
        observe(on: queue, successBlock: { _ in }, failureBlock: block)
    }

    @discardableResult
    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) -> Guarantee<Value>
    ) -> Guarantee<Value> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    func recover<T: Thenable>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) throws -> T
    ) -> Promise<Value> where T.Value == Value {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    func ensure(
        on queue: DispatchQueue? = nil,
        _ block: @escaping () -> Void
    ) -> Promise<Value> {
        observe(on: queue) { value in
            block()
            return value
        } failureBlock: { _ in
            block()
        }
    }

    @discardableResult
    func cauterize() -> Self { self }

    func asVoid() -> Promise<Void> { map { _ in } }
}

fileprivate extension Thenable where Self: Catchable {
    func observe<T>(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> T,
        failureBlock: @escaping (Error) throws -> Void = { _ in }
    ) -> Promise<T> {
        let (promise, future) = Promise<T>.pending()
        observe(on: queue) { result in
            do {
                switch result {
                case .success(let value):
                    future.resolve(try successBlock(value))
                case .failure(let error):
                    try failureBlock(error)
                    future.reject(error)
                }
            } catch {
                future.reject(error)
            }
        }
        return promise
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) -> Value,
        failureBlock: @escaping (Error) -> Value
    ) -> Guarantee<Value> {
        let (guarantee, future) = Guarantee<Value>.pending()
        observe(on: queue) { result in
            switch result {
            case .success(let value):
                future.resolve(successBlock(value))
            case .failure(let error):
                future.resolve(failureBlock(error))
            }
        }
        return guarantee
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) -> Value,
        failureBlock: @escaping (Error) -> Guarantee<Value>
    ) -> Guarantee<Value> {
        let (guarantee, future) = Guarantee<Value>.pending()
        observe(on: queue) { result in
            switch result {
            case .success(let value):
                future.resolve(successBlock(value))
            case .failure(let error):
                future.resolve(on: queue, with: failureBlock(error))
            }
        }
        return guarantee
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> Value,
        failureBlock: @escaping (Error) throws -> Value
    ) -> Promise<Value> {
        let (promise, future) = Promise<Value>.pending()
        observe(on: queue) { result in
            do {
                switch result {
                case .success(let value):
                    future.resolve(try successBlock(value))
                case .failure(let error):
                    future.resolve(try failureBlock(error))
                }
            } catch {
                future.reject(error)
            }
        }
        return promise
    }

    func observe<T: Thenable>(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> Value,
        failureBlock: @escaping (Error) throws -> T
    ) -> Promise<Value> where T.Value == Value {
        let (promise, future) = Promise<Value>.pending()
        observe(on: queue) { result in
            do {
                switch result {
                case .success(let value):
                    future.resolve(try successBlock(value))
                case .failure(let error):
                    future.resolve(on: queue, with: try failureBlock(error))
                }
            } catch {
                future.reject(error)
            }
        }
        return promise
    }
}

public extension Catchable where Value == Void {
    @discardableResult
    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) -> Void
    ) -> Guarantee<Void> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) throws -> Void
    ) -> Promise<Void> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }
}
