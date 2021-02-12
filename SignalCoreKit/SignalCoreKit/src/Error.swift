//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public struct OWSAssertionError: Error {
    public let errorCode: Int = SCKError.Code.assertionError.rawValue
    public let description: String
    public init(_ description: String,
                file: String = #file,
                function: String = #function,
                line: Int = #line) {
        owsFailDebug("assertionError: \(description)", file: file, function: function, line: line)
        self.description = description
    }
}

// An error that won't assert.
public struct OWSGenericError: Error {
    public let errorCode: Int = SCKError.Code.genericError.rawValue
    public let description: String
    public init(_ description: String) {
        self.description = description
    }
}
