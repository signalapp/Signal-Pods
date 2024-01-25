//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Result {
    /// Helper function for avoid the pyramid of doom when dealing with async functions that return
    /// `Result`. Either returns the `Success` value if `self` is `success`, or if `self` is
    /// `failure`, then calls `completionBlock` with `self` and returns `nil`. The `nil` can then be
    /// checked as part of a guard expression containing a return statement, helping ensure that
    /// `completionBlock` isn't invoked more than once.
    ///
    /// # Example usage
    /// ```
    /// asyncFunction {
    ///     guard let returnValue = $0.successOr(completion: completionBlock) else { return }
    ///
    ///     secondAsyncFunction(using: returnValue, completion: completionBlock)
    /// }
    /// ```
    /// When using a switch, this might look like:
    /// ```
    /// asyncFunction {
    ///     switch $0 {
    ///     case .success(let returnValue):
    ///         secondAsyncFunction(using: returnValue, completion: completionBlock)
    ///     case .failure(let error):
    ///         completionBlock(.failure(error))
    ///     }
    /// }
    /// ```
    ///
    func successOr<Value>(completion: (Result<Value, Failure>) -> Void) -> Success? {
        switch self {
        case .success(let success):
            return success
        case .failure(let error):
            completion(.failure(error))
            return nil
        }
    }
}
