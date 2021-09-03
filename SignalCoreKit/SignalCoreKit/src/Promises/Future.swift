//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public final class Future<Value> {
    public typealias ResultType = Swift.Result<Value, Error>
    public private(set) var isSealed = false
    public private(set) var result: ResultType?

    public init() {}

    public convenience init(value: Value) {
        self.init()
        sealResult(.success(value))
    }

    public convenience init(error: Error) {
        self.init()
        sealResult(.failure(error))
    }

    private var observers = [(ResultType) -> Void]()
    private let observerLock = UnfairLock()
    public func observe(on queue: DispatchQueue? = nil, block: @escaping (ResultType) -> Void) {
        observerLock.withLock {
            func execute(_ result: ResultType) {
                // If a queue is not specified, try and run on the main
                // queue. Eventually we'll want to switch this default,
                // but for now it matches the behavior we expect from
                // PromiseKit.
                (queue ?? .main).asyncIfNecessary {
                    block(result)
                }
            }

            if let result = result {
                execute(result)
                return
            }
            observers.append(execute)
        }
    }
    private func sealResult(_ result: ResultType) {
        observerLock.withLock {
            guard !isSealed else { return }
            self.result = result
            self.isSealed = true
            observers.forEach { $0(result) }
            observers.removeAll()
        }
    }

    public func resolve(_ value: Value) {
        sealResult(.success(value))
    }

    public func resolve<T: Thenable>(
        on queue: DispatchQueue? = nil,
        with thenable: T
    ) where T.Value == Value {
        thenable.done(on: queue) { value in
            self.sealResult(.success(value))
        }.catch { error in
            self.sealResult(.failure(error))
        }
    }

    public func reject(_ error: Error) {
        sealResult(.failure(error))
    }
}

public extension Future where Value == Void {
    func resolve() { resolve(()) }
}
