//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol AttestableHttpClient {
    var authCallable: AuthHttpCallable { get }
}
