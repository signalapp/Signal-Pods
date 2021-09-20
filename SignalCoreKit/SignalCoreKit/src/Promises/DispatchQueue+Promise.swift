//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public enum PromiseNamespace { case promise }

public extension DispatchQueue {
    func asyncIfNecessary(
        execute work: @escaping @convention(block) () -> Void
    ) {
        if DispatchQueueIsCurrentQueue(self), _CurrentStackUsage() < 0.8 {
            work()
        } else {
            async { work() }
        }
    }
    func async<T>(_ namespace: PromiseNamespace, execute work: @escaping () -> T) -> Guarantee<T> {
        let (guarantee, future) = Guarantee<T>.pending()
        async {
            future.resolve(work())
        }
        return guarantee
    }
    func async<T>(_ namespace: PromiseNamespace, execute work: @escaping () throws -> T) -> Promise<T> {
        let (promise, future) = Promise<T>.pending()
        async {
            do {
                future.resolve(try work())
            } catch {
                future.reject(error)
            }
        }
        return promise
    }
}

public extension Optional where Wrapped == DispatchQueue {
    func asyncIfNecessary(
        execute work: @escaping @convention(block) () -> Void
    ) {
        switch self {
        case .some(let queue):
            queue.asyncIfNecessary(execute: work)
        case .none:
            work()
        }
    }
}
