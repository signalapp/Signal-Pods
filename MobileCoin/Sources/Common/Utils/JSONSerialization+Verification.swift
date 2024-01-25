//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension JSONSerialization {
    static func verify(jsonString: String) -> Result<(), InvalidInputError> {
        guard let jsonDataToVerify = jsonString.data(using: String.Encoding.utf8) else {
            return .success(())
        }
        do {
            _ = try JSONSerialization.jsonObject(with: jsonDataToVerify)
            return .success(())
        } catch {
            return .failure(InvalidInputError(
                "Error deserializing JSON: \(error.localizedDescription)")
            )
        }
    }
}
