//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Collection {
    func collectResult<Value, Failure: Error>() -> Result<[Value], Failure>
        where Element == Result<Value, Failure>
    {
        reduce(into: .success([])) { accumResult, valueResult in
            accumResult = accumResult.flatMap { accumSuccess in
                valueResult.map { valueSuccess in
                    accumSuccess + [valueSuccess]
                }
            }
        }
    }
}
