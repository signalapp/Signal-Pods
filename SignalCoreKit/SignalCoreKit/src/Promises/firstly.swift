//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public func firstly<T: Thenable>(
    _ block: () throws -> T
) -> Promise<T.Value> {
    let (promise, future) = Promise<T.Value>.pending()
    do {
        future.resolve(with: try block())
    } catch {
        future.reject(error)
    }
    return promise
}

public func firstly<T>(_ block: () -> Guarantee<T>) -> Guarantee<T> {
    let (promise, future) = Guarantee<T>.pending()
    future.resolve(with: block())
    return promise
}

public func firstly<T: Thenable>(
    on queue: DispatchQueue,
    _ block: @escaping () throws -> T
) -> Promise<T.Value> {
    let (promise, future) = Promise<T.Value>.pending()
    queue.asyncIfNecessary {
        do {
            future.resolve(on: queue, with: try block())
        } catch {
            future.reject(error)
        }
    }
    return promise
}

public func firstly<T>(on queue: DispatchQueue, _ block: @escaping () -> Guarantee<T>) -> Guarantee<T> {
    let (promise, future) = Guarantee<T>.pending()
    queue.asyncIfNecessary {
        future.resolve(on: queue, with: block())
    }
    return promise
}

public func firstly<T>(
    on queue: DispatchQueue,
    _ block: @escaping () throws -> T
) -> Promise<T> {
    let (promise, future) = Promise<T>.pending()
    queue.asyncIfNecessary {
        do {
            future.resolve(try block())
        } catch {
            future.reject(error)
        }
    }
    return promise
}

public func firstly<T>(
    on queue: DispatchQueue,
    _ block: @escaping () -> T
) -> Guarantee<T> {
    let (guarantee, future) = Guarantee<T>.pending()
    queue.asyncIfNecessary {
        future.resolve(block())
    }
    return guarantee
}
