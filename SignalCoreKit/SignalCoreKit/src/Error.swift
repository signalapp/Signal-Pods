//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public struct OWSAssertionError: Error {
    #if TESTABLE_BUILD
    public static var test_skipAssertions = false
    #endif

    public let description: String
    public init(
        _ description: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        #if TESTABLE_BUILD
        if Self.test_skipAssertions {
            Logger.warn("assertionError: \(description)")
        } else {
            owsFailDebug("assertionError: \(description)", file: file, function: function, line: line)
        }
        #else
        owsFailDebug("assertionError: \(description)", file: file, function: function, line: line)
        #endif
        self.description = description
    }
}

// An error that won't assert.
public struct OWSGenericError: Error {
    public let description: String
    public init(_ description: String) {
        self.description = description
    }
}
