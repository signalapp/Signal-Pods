//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum HexEncoding {
    static func data(fromHexEncodedString hexEncodedString: String) -> Data? {
        guard hexEncodedString.count.isMultiple(of: 2) else { return nil }
        let byteStrings = hexEncodedString.chunked(maxLength: 2)

        let bytes = byteStrings.compactMap { UInt8($0, radix: 16) }
        guard byteStrings.count == bytes.count else { return nil }

        return Data(bytes)
    }

    private static let hexCharacters = Array("0123456789abcdef")

    static func hexEncodedString(fromData data: Data) -> String {
        data.reduce(into: "") { result, byte in
            result.append(Self.hexCharacters[Int(byte / 0x10)])
            result.append(Self.hexCharacters[Int(byte % 0x10)])
        }
    }
}
