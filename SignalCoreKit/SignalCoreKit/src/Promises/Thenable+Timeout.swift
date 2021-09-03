//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Thenable {
    func nilTimeout(seconds: TimeInterval) -> Promise<Value?> {
        let timeout: Promise<Value?> = Guarantee.after(seconds: seconds).asPromise().map { nil }

        return Promise.race([
            map { (a: Value?) -> (Value?, Bool) in
                (a, false)
            },
            timeout.map { (a: Value?) -> (Value?, Bool) in
                (a, true)
            }
        ]).map { result, didTimeout in
            if didTimeout {
                Logger.info("Timed out, returning nil value.")
            }
            return result
        }
    }

    func timeout(seconds: TimeInterval, substituteValue: Value) -> Promise<Value> {
        let timeout: Promise<Value> = Guarantee.after(seconds: seconds).asPromise().map {
            return substituteValue
        }

        return Promise.race([
            map { ($0, false) },
            timeout.map { ($0, true) }
        ]).map { result, didTimeout in
            if didTimeout {
                Logger.info("Timed out, returning substitute value.")
            }
            return result
        }
    }
}

public extension Promise {
    func timeout(seconds: TimeInterval, description: String? = nil, timeoutErrorBlock: @escaping () -> Error) -> Promise<Value> {
        let timeout: Promise<Value> = Guarantee.after(seconds: seconds).asPromise().map {
            throw TimeoutError(underlyingError: timeoutErrorBlock())
        }

        return Promise.race([self, timeout]).recover { error -> Promise<Value> in
            switch error {
            case let timeoutError as TimeoutError:
                if let description = description {
                    Logger.info("Timed out, throwing error: \(description).")
                } else {
                    Logger.info("Timed out, throwing error.")
                }
                return Promise(error: timeoutError.underlyingError)
            default:
                return Promise(error: error)
            }
        }
    }
}

struct TimeoutError: Error {
    let underlyingError: Error
}

public extension Thenable where Value == Void {
    func timeout(seconds: TimeInterval) -> Promise<Void> {
        return timeout(seconds: seconds, substituteValue: ())
    }
}
