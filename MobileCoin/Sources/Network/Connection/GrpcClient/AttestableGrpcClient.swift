//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

protocol AttestableGrpcClient {
    var authCallable: AuthGrpcCallable { get }
}
