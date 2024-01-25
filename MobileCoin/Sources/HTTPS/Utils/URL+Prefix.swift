//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension URL {
    static func prefix(_ url: URL, pathComponents: [String]) -> URL? {
        let prunedComponents = pathComponents.map({
                $0.hasPrefix("/") ? String($0.dropFirst()) : $0
        })
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.path = "/" + (url.pathComponents + prunedComponents).joined(separator: "/")
        return components.url
    }
}
