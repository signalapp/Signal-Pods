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
    func timeout(
        seconds: TimeInterval,
        ticksWhileSuspended: Bool = false,
        description: String? = nil,
        timeoutErrorBlock: @escaping () -> Error
    ) -> Promise<Value> {
        let timeout: Promise<Value>
        if ticksWhileSuspended {
            timeout = Guarantee.after(wallInterval: seconds).asPromise().map { throw TimeoutError.wallTimeout }
        } else {
            timeout = Guarantee.after(seconds: seconds).asPromise().map { throw TimeoutError.relativeTimeout }
        }

        return Promise.race([self, timeout]).recover { error -> Promise<Value> in
            switch error {
            case is TimeoutError:
                let underlyingError = timeoutErrorBlock()
                let prefix: String
                if let description = description {
                    prefix = "\(description) timed out:"
                } else {
                    prefix = "Timed out:"
                }
                Logger.info("\(prefix): \(error). Resolving promise with underlying error: \(underlyingError)")
                return Promise(error: underlyingError)
            default:
                return Promise(error: error)
            }
        }
    }
}

enum TimeoutError: Error {
    case wallTimeout
    case relativeTimeout
}

public extension Thenable where Value == Void {
    func timeout(seconds: TimeInterval) -> Promise<Void> {
        return timeout(seconds: seconds, substituteValue: ())
    }
}
