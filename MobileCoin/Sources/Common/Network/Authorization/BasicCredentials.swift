//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

struct BasicCredentials {
    let username: String
    let password: String

    var authorizationHeaderValue: String {
        let credentials = "\(username):\(password)"
        return "Basic \(Data(credentials.utf8).base64EncodedString())"
    }
}
