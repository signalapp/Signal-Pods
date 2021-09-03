//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Thenable {
    static func race<T: Thenable>(_ thenables: T...) -> Promise<T.Value> where T.Value == Value {
        race(thenables)
    }

    static func race<T: Thenable>(_ thenables: [T]) -> Promise<T.Value> where T.Value == Value {
        let (returnPromise, future) = Promise<T.Value>.pending()

        for thenable in thenables {
            thenable.observe(on: nil) { result in
                switch result {
                case .success(let result):
                    guard !future.isSealed else { return }
                    future.resolve(result)
                case .failure(let error):
                    guard !future.isSealed else { return }
                    future.reject(error)
                }
            }
        }

        return returnPromise
    }
}
