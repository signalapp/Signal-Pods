//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

func performAsync<Value1, Value2, Failure: Error>(
    body1: (@escaping (Result<Value1, Failure>) -> Void) -> Void,
    body2: (@escaping (Result<Value2, Failure>) -> Void) -> Void,
    completion: @escaping (Result<(Value1, Value2), Failure>) -> Void
) {
    var results: (Value1?, Value2?)
    var completedTaskCount: Int32 = 0

    // This allows us to prevent invoking `completion` more than once. We only need to use this for
    // the failure case since the state of "all success" and the state of "at least one failure" are
    // mutually exclusive.
    var callbackFailureInvoked: Int32 = 0

    func callback<Value>(success: @escaping (Value) -> Void) -> (Result<Value, Failure>) -> Void {
        { result in
            switch result {
            case .success(let value):
                success(value)

                // Check if all tasks are complete
                if OSAtomicIncrement32(&completedTaskCount) == 2 {
                    guard let result1 = results.0, let result2 = results.1 else {
                        // This condition should never be reached and indicates a programming error.
                        logger.fatalError("Results not ready: \(redacting: results)")
                    }
                    completion(.success((result1, result2)))
                }
            case .failure(let error):
                if OSAtomicIncrement32(&callbackFailureInvoked) == 1 {
                    completion(.failure(error))
                }
            }
        }
    }

    // Invoke all closures
    body1(callback(success: { results.0 = $0 }))
    body2(callback(success: { results.1 = $0 }))
}

#if swift(>=5.5)
// swiftlint:disable superfluous_disable_command
// swiftlint:disable multiline_parameters

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public func withTimeout<T>(
    seconds: TimeInterval,
    block: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        let deadline = Date(timeIntervalSinceNow: seconds)
        group.addTask {
            try await block()
        }
        group.addTask {
            let interval = deadline.timeIntervalSinceNow
            if interval > 0 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            try Task.checkCancellation()
            throw TimedOutError()
        }
        guard let result = try await group.next() else {
            throw TimedOutError()
        }
        group.cancelAll()
        return result
    }
}

#endif
