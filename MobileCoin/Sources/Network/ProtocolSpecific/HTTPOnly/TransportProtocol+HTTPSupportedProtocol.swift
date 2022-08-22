//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension TransportProtocol: SupportedProtocols {
    public static var supportedProtocols: [TransportProtocol] {
        [.http]
    }
}
