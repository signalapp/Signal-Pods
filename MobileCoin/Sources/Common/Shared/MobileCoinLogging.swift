//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count prefixed_toplevel_constant

import Foundation
import Logging

public enum MobileCoinLogging {
    public static var logSensitiveData = false {
        willSet {
            guard logSensitiveDataInternal.set(newValue) else {
                logger.preconditionFailure(
                    "logSensitiveData can only be set prior to using the MobileCoin SDK.")
            }
        }
    }
}

internal let logger = Logger(label: "com.mobilecoin", factory: ContextPrefixLogHandler.init)

private struct ContextPrefixLogHandler: LogHandler {
    static let ENABLE_LOG_FUNCTION_METADATA_KEY = "LOG_FUNCTION_METADATA_KEY"

    private var logger: Logger

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { logger[metadataKey: metadataKey] }
        set { logger[metadataKey: metadataKey] = newValue }
    }

    init(label: String) {
        self.logger = Logger(label: label)
    }

    // `metadata` isn't currently accessible via `logger`, so there's not much we can do.
    // Fortunately, it's not accessed by `Logger` either, so we're just going to ignore it.
    var metadata: Logger.Metadata {
        get { [:] }
        set { _ = newValue }
    }

    var logLevel: Logger.Level {
        get { logger.logLevel }
        set { logger.logLevel = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        var (message, metadata) = (message, metadata)

        // Remove log function metadata entry and add file/line/function name if it was enabled.
        if metadata?
            .removeValue(forKey: ContextPrefixLogHandler.ENABLE_LOG_FUNCTION_METADATA_KEY) != nil
        {
            let filename = URL(fileURLWithPath: file, isDirectory: false).lastPathComponent
            message = "\(filename):\(line):\(function) - \(message)"
        }

        logger.log(
            level: level,
            message,
            metadata: metadata,
            source: source,
            file: file,
            function: function,
            line: line)
    }
}

// The value of `logSensitiveDataInternal` gets locked in place upon first read.
private let logSensitiveDataInternal = ImmutableOnceReadLock(false)

extension Logger {
    func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        if condition() {
            assertionFailure(message(), file: file, function: function, line: line)
        }
    }

    func precondition(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        if condition() {
            preconditionFailure(message(), file: file, function: function, line: line)
        }
    }

    func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let message = message()
        error("\(message)", file: "\(file)", function: function, line: line)
        Swift.assertionFailure(message, file: file, line: line)
    }

    func preconditionFailure(
        _ message: @autoclosure () -> String = String(),
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) -> Never {
        let message = message()
        critical("\(message)", file: "\(file)", function: function, line: line)
        return Swift.preconditionFailure(message, file: file, line: line)
    }

    func fatalError(
        _ message: @autoclosure () -> String = String(),
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) -> Never {
        let message = message()
        critical("\(message)", file: "\(file)", function: function, line: line)
        return Swift.fatalError(message, file: file, line: line)
    }
}

extension Logger {
    func trace(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        trace(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    func debug(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        debug(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    func info(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        info(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    func notice(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        notice(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    func warning(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        warning(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    func error(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        error(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    func critical(
        _ message: @autoclosure () -> Logger.Message,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard !sensitive || logSensitiveDataInternal.get() else { return }

        let metadata = logFunction ? { Self.addingLogFunctionKey(metadata()) } : metadata
        critical(
            message(),
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line)
    }

    private static func addingLogFunctionKey(_ metadata: Logger.Metadata?) -> Logger.Metadata {
        var metadata = metadata ?? Logger.Metadata()
        metadata[ContextPrefixLogHandler.ENABLE_LOG_FUNCTION_METADATA_KEY] = "1"
        return metadata
    }
}

extension Logger {
    func trace(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        trace(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }

    func debug(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        debug(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }

    func info(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        info(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }

    func notice(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        notice(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }

    func warning(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        warning(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }

    func error(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        error(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }

    func critical(
        _ message: @autoclosure () -> String,
        metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        sensitive: Bool = false,
        logFunction: Bool = true,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        critical(
            Message(stringLiteral: message()),
            metadata: metadata(),
            source: source(),
            sensitive: sensitive,
            logFunction: logFunction,
            file: file,
            function: function,
            line: line)
    }
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation<T>(redacting value: T)
        where T: CustomStringConvertible & TextOutputStreamable
    {
        if logSensitiveDataInternal.get() {
            appendInterpolation(value)
        } else {
            appendInterpolation("<redacted>")
        }
    }

    mutating func appendInterpolation<T: TextOutputStreamable>(redacting value: T) {
        if logSensitiveDataInternal.get() {
            appendInterpolation(value)
        } else {
            appendInterpolation("<redacted>")
        }
    }

    mutating func appendInterpolation<T: CustomStringConvertible>(redacting value: T) {
        if logSensitiveDataInternal.get() {
            appendInterpolation(value)
        } else {
            appendInterpolation("<redacted>")
        }
    }

    mutating func appendInterpolation<T>(redacting value: T) {
        if logSensitiveDataInternal.get() {
            appendInterpolation(value)
        } else {
            appendInterpolation("<redacted>")
        }
    }

    mutating func appendInterpolation(redacting value: Any.Type) {
        if logSensitiveDataInternal.get() {
            appendInterpolation(value)
        } else {
            appendInterpolation("<redacted>")
        }
    }

    mutating func appendInterpolation<T: CustomRedactingStringConvertible>(redacting value: T) {
        appendInterpolation(value.redactingDescription)
    }
}
