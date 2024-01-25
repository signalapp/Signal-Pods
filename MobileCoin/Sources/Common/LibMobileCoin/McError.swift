//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

func withMcInfallible(_ body: () -> OpaquePointer?) -> OpaquePointer {
    guard let value = body() else {
        logger.fatalError("Error: \(#function): Infallible LibMobileCoin function failed")
    }
    return value
}

func withMcError(_ body: (inout UnsafeMutablePointer<McError>?) -> OpaquePointer?)
    -> Result<OpaquePointer, LibMobileCoinError>
{
    var error: UnsafeMutablePointer<McError>?
    guard let value = body(&error) else {
        guard let mcError = error else {
            // Safety: This condition should never occur and indicates a programming error.
            logger.fatalError("Error: \(#function): block returned failure but out_error == NULL.")
        }
        let err: LibMobileCoinError
        do {
            err = try LibMobileCoinError.make(consuming: mcError).get()
        } catch {
            logger.fatalError("Error: \(#function): \(error)")
        }
        guard err.errorCode != .panic else {
            logger.fatalError("LibMobileCoin function panicked: \(redacting: err.description)")
        }
        return .failure(err)
    }
    return .success(value)
}

func withMcInfallible(_ body: () -> Bool) {
    guard body() else {
        logger.fatalError("Error: \(#function): Infallible LibMobileCoin function failed.")
    }
}

func withMcError<T>(_ body: (inout UnsafeMutablePointer<McError>?) -> T)
    -> Result<T, LibMobileCoinError>
{
    var error: UnsafeMutablePointer<McError>?
    let value = body(&error)

    if let mcError = error {
        let err: LibMobileCoinError
        do {
            err = try LibMobileCoinError.make(consuming: mcError).get()
        } catch {
            logger.fatalError("Error: \(#function): \(error)")
        }
        guard err.errorCode != .panic else {
            logger.fatalError("LibMobileCoin function panicked: \(redacting: err.description)")
        }
        return .failure(err)
    }
    return .success((value))
}

func withMcError(_ body: (inout UnsafeMutablePointer<McError>?) -> Bool)
    -> Result<(), LibMobileCoinError>
{
    var error: UnsafeMutablePointer<McError>?
    guard body(&error) else {
        guard let mcError = error else {
            // Safety: This condition should never occur and indicates a programming error.
            logger.fatalError("Error: \(#function): block returned failure but out_error == NULL.")
        }
        let err: LibMobileCoinError
        do {
            err = try LibMobileCoinError.make(consuming: mcError).get()
        } catch {
            logger.fatalError("Error: \(#function): \(error)")
        }
        guard err.errorCode != .panic else {
            logger.fatalError("LibMobileCoin function panicked: \(redacting: err.description)")
        }
        return .failure(err)
    }
    return .success(())
}

func withMcInfallibleReturningOptional<T>(_ body: () -> T?) -> T {
    guard let value = body() else {
        logger.fatalError("Error: \(#function): Infallible LibMobileCoin function failed.")
    }
    return value
}

func withMcErrorReturningOptional<T>(_ body: (inout UnsafeMutablePointer<McError>?) -> T?)
    -> Result<T, LibMobileCoinError>
{
    var error: UnsafeMutablePointer<McError>?
    guard let value = body(&error) else {
        guard let mcError = error else {
            // Safety: This condition should never occur and indicates a programming error.
            logger.fatalError("Error: \(#function): block returned failure but out_error == NULL.")
        }
        let err: LibMobileCoinError
        do {
            err = try LibMobileCoinError.make(consuming: mcError).get()
        } catch {
            logger.fatalError("Error: \(#function): \(error)")
        }
        guard err.errorCode != .panic else {
            logger.fatalError("LibMobileCoin function panicked: \(redacting: err.description)")
        }
        return .failure(err)
    }
    return .success(value)
}

func withMcErrorReturningArrayCount(_ body: (inout UnsafeMutablePointer<McError>?) -> Int)
    -> Result<Int, LibMobileCoinError>
{
    var error: UnsafeMutablePointer<McError>?
    let value = body(&error)
    guard value >= 0 else {
        guard let mcError = error else {
            // Safety: This condition should never occur and indicates a programming error.
            logger.fatalError("Error: \(#function): block returned failure but out_error == NULL.")
        }
        let err: LibMobileCoinError
        do {
            err = try LibMobileCoinError.make(consuming: mcError).get()
        } catch {
            logger.fatalError("Error: \(#function): \(error)")
        }
        guard err.errorCode != .panic else {
            logger.fatalError("LibMobileCoin function panicked: \(redacting: err.description)")
        }
        return .failure(err)
    }
    return .success(value)
}
