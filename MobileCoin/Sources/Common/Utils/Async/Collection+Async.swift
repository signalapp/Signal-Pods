//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Collection {
    func mapAsync<Value, Failure: Error>(
        _ body: (Element, @escaping (Result<Value, Failure>) -> Void) -> Void,
        serialQueue: DispatchQueue,
        completion: @escaping (Result<[Value], Failure>) -> Void
    ) {
        guard count > 0 else {
            serialQueue.async {
                completion(.success([]))
            }
            return
        }

        // Store this in case the collection is mutated while waiting for the results
        let taskCount = self.count

        var results: [Value?] = Array(repeating: nil, count: taskCount)
        var completedTaskCount: Int32 = 0

        // This allows us to prevent invoking `completion` more than once. We only need to use this
        // for the failure case since the state of "all success" and the state of "at least one
        // failure" are mutually exclusive.
        var callbackFailureInvoked: Int32 = 0

        // Invoke all closures
        for (i, elem) in enumerated() {
            body(elem) {
                switch $0 {
                case .success(let value):
                    results[i] = value

                    // Check if all tasks are complete
                    if OSAtomicIncrement32(&completedTaskCount) == taskCount {
                        let returnedResults = results.compactMap { $0 }
                        guard returnedResults.count == taskCount else {
                            if OSAtomicIncrement32(&callbackFailureInvoked) == 1 {
                                logger.fatalError(
                                    "returnedResults.count (\(returnedResults.count)) != " +
                                        "taskCount (\(taskCount)), results: \(redacting: results)")
                            }
                            return
                        }
                        completion(.success(returnedResults))
                    }
                case .failure(let error):
                    if OSAtomicIncrement32(&callbackFailureInvoked) == 1 {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}
