//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Result {
    func flatMap<NewSuccess, ExistingError>(
        _ transform: (Success) throws -> NewSuccess
    ) -> Result<NewSuccess, ExistingError> {
        do {
            let value = try get()
            let newSuccess = try transform(value)
            return .success(newSuccess)
        } catch let error as ExistingError {
            return .failure(error)
        } catch {
            // Should never happen since transformer error is type checked.
            fatalError("Unexpected error type: \(error)")
        }
    }
}
