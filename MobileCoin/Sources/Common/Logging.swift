// swiftlint:disable:this file_name

//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable prefixed_toplevel_constant

import Logging

internal let logger = Logger(label: "com.mobilecoin")

extension Logger {
    func fatalError(
        _ message: @autoclosure () -> String = String(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> Never {
        let message = message()
        critical("\(message)")
        return Swift.fatalError(message, file: file, line: line)
    }
}
