//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

/**
 * We synchronize access to state in this class using this queue.
 */
public func assertOnQueue(_ queue: DispatchQueue) {
    if #available(iOS 10.0, *) {
        dispatchPrecondition(condition: .onQueue(queue))
    } else {
        // Skipping check on <iOS10, since syntax is different and it's just a development convenience.
    }
}

@inlinable
public func AssertIsOnMainThread(file: String = #file,
                                 function: String = #function,
                                 line: Int = #line) {
    if !Thread.isMainThread {
        owsFailDebug("Must be on main thread.", file: file, function: function, line: line)
    }
}

@inlinable
public func owsFailDebug(_ logMessage: String,
                         file: String = #file,
                         function: String = #function,
                         line: Int = #line) {
    Logger.error(logMessage, file: file, function: function, line: line)
    Logger.flush()
    let formattedMessage = owsFormatLogMessage(logMessage, file: file, function: function, line: line)
    assertionFailure(formattedMessage)
}

@inlinable
public func owsFail(_ logMessage: String,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) -> Never {
    OWSSwiftUtils.logStackTrace()
    owsFailDebug(logMessage, file: file, function: function, line: line)
    let formattedMessage = owsFormatLogMessage(logMessage, file: file, function: function, line: line)
    fatalError(formattedMessage)
}

@inlinable
public func owsAssertDebug(_ condition: Bool,
                           _ message: @autoclosure () -> String = String(),
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line) {
    if !condition {
        let message: String = message()
        owsFailDebug(message.isEmpty ? "Assertion failed." : message,
                     file: file, function: function, line: line)
    }
}

@inlinable
public func owsAssert(_ condition: Bool,
                      _ message: @autoclosure () -> String = String(),
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
    if !condition {
        let message: String = message()
        owsFail(message.isEmpty ? "Assertion failed." : message,
                file: file, function: function, line: line)
    }
}

@inlinable
public func notImplemented(file: String = #file,
                           function: String = #function,
                           line: Int = #line) -> Never {
    owsFail("Method not implemented.", file: file, function: function, line: line)
}

@objc
public class OWSSwiftUtils: NSObject {
    // This method can be invoked from Obj-C to exit the app.
    @objc
    public class func owsFail(_ logMessage: String,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line) -> Never {

        logStackTrace()
        owsFailDebug(logMessage, file: file, function: function, line: line)
        let formattedMessage = owsFormatLogMessage(logMessage, file: file, function: function, line: line)
        fatalError(formattedMessage)
    }

    @objc
    public class func logStackTrace() {
        Thread.callStackSymbols.forEach { Logger.error($0) }
    }
}
