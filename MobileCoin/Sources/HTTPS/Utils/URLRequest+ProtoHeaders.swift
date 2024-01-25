//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension URLRequest {
    mutating func addProtoHeaders() {
        let contentType = (fieldName:"Content-Type", value:"application/x-protobuf")
        self.setValue(contentType.value, forHTTPHeaderField: contentType.fieldName)

        let accept = (fieldName:"Accept", value:"application/x-protobuf")
        self.addValue(accept.value, forHTTPHeaderField: accept.fieldName)
    }

    mutating func addHeaders(_ headers: [String: String]) {
        headers.forEach { headerFieldName, value in
            self.setValue(value, forHTTPHeaderField: headerFieldName)
        }
    }
}
