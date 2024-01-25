//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension DataConvertible {
    init?(hexEncoded hexEncodedString: String) {
        guard let data = HexEncoding.data(fromHexEncodedString: hexEncodedString) else {
            return nil
        }
        self.init(data)
    }

    func hexEncodedString() -> String {
        HexEncoding.hexEncodedString(fromData: self.data)
    }
}

extension Data {
    public func hexEncodedString() -> String {
        HexEncoding.hexEncodedString(fromData: self)
    }
}
