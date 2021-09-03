//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public protocol Thenable: AnyObject {
    associatedtype Value
    var result: Result<Value, Error>? { get }
    init()
    func observe(on queue: DispatchQueue?, block: @escaping (Result<Value, Error>) -> Void)
}

public extension Thenable {
    func map<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) throws -> T
    ) -> Promise<T> {
        observe(on: queue, block: block)
    }

    func done(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) throws -> Void
    ) -> Promise<Void> {
        observe(on: queue, block: block)
    }

    func then<T: Thenable>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) throws -> T
    ) -> Promise<T.Value> {
        let (promise, future) = Promise<T.Value>.pending()
        observe(on: queue) { result in
            do {
                switch result {
                case .success(let value):
                    future.resolve(on: queue, with: try block(value))
                case .failure(let error):
                    future.reject(error)
                }
            } catch {
                future.reject(error)
            }
        }
        return promise
    }

    var value: Value? {
        guard case .success(let value) = result else { return nil }
        return value
    }

    func asVoid() -> Promise<Void> { map { _ in } }
}

fileprivate extension Thenable {
    func observe<T>(
        on queue: DispatchQueue?,
        block: @escaping (Value) throws -> T
    ) -> Promise<T> {
        let (promise, future) = Promise<T>.pending()
        observe(on: queue) { result in
            do {
                switch result {
                case .success(let value):
                    future.resolve(try block(value))
                case .failure(let error):
                    future.reject(error)
                }
            } catch {
                future.reject(error)
            }
        }
        return promise
    }
}
