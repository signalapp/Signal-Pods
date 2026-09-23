//
// Copyright 2026 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SignalFfi

/// Exports a backup to newline-delimited JSON (JSONL), frame by frame.
///
/// Optionally validates each frame and the whole backup during export. Sanitization (filtering
/// disappearing messages, stripping view-once attachments) is always applied.
///
/// This class is not thread-safe.
///
/// Write ``initialChunk`` first, then each non-nil ``FrameExportResult/line`` returned by
/// ``exportFrames(_:)``, adding a newline after each. Call ``finishExport()`` after exporting
/// all frames to run the final whole-backup validation checks. Native resources are released
/// automatically when the exporter is deallocated.
public class BackupJsonExporter: NativeHandleOwner<SignalMutPointerBackupJsonExporter> {
    /// The result of exporting a single backup frame.
    public struct FrameExportResult: Sendable {
        /// The JSON line, without a trailing newline, or nil if the frame was filtered out or could not be rendered.
        public let line: String?
        /// A rendering or validation error, or nil if the frame exported cleanly.
        public let errorMessage: String?

        public init(line: String?, errorMessage: String?) {
            self.line = line
            self.errorMessage = errorMessage
        }
    }

    /// Initializes the streaming exporter and returns the first set of output lines.
    ///
    /// - Parameters:
    ///   - backupInfo: The serialized BackupInfo protobuf without a varint length prefix.
    ///   - validate: Whether to run semantic validation during export.
    /// - Throws: ``MessageBackupValidationError`` if the BackupInfo cannot be parsed or validated.
    public convenience init<Bytes: ContiguousBytes>(backupInfo: Bytes, validate: Bool = true) throws {
        let handle = try backupInfo.withUnsafeBorrowedBuffer { backupInfo in
            try invokeFnReturningValueByPointer(.init()) {
                signal_backup_json_exporter_new($0, backupInfo, validate)
            }
        }
        self.init(owned: NonNull(handle)!)
    }

    internal required init(owned handle: NonNull<SignalMutPointerBackupJsonExporter>) {
        super.init(owned: handle)
    }

    override internal class func destroyNativeHandle(
        _ handle: NonNull<SignalMutPointerBackupJsonExporter>
    ) -> SignalFfiErrorRef? {
        signal_backup_json_exporter_destroy(handle.pointer)
    }

    /// The initial JSON line containing BackupInfo, without a trailing newline.
    public var initialChunk: String {
        failOnError {
            try NativeNice.BackupJsonExporter_GetInitialChunk(exporter: self)
        }
    }

    /// Exports a batch of complete, varint-delimited Frame protobuf messages.
    ///
    /// Call repeatedly to stream frames through the exporter. Results are returned in input order,
    /// including entries for filtered frames. Rendering and semantic validation errors are reported
    /// in each result so that export can continue.
    ///
    /// - Throws: ``MessageBackupValidationError`` if the frame bytes cannot be parsed.
    public func exportFrames(_ frames: Data) throws -> [FrameExportResult] {
        try NativeNice.BackupJsonExporter_ExportFrames(exporter: self, frames: frames).map {
            FrameExportResult(line: $0.0, errorMessage: $0.1)
        }
    }

    /// Completes the export and runs any final whole-backup validation checks.
    ///
    /// Call once after exporting all frames, even if individual frames reported errors.
    ///
    /// - Throws: ``MessageBackupValidationError`` if whole-backup validation fails.
    public func finishExport() throws {
        try NativeNice.BackupJsonExporter_Finish(exporter: self)
    }
}

extension SignalMutPointerBackupJsonExporter: SignalMutPointer {
    public typealias ConstPointer = SignalConstPointerBackupJsonExporter

    public init(untyped: OpaquePointer?) {
        self.init(raw: untyped)
    }

    public func toOpaque() -> OpaquePointer? {
        self.raw
    }

    public func const() -> Self.ConstPointer {
        Self.ConstPointer(raw: self.raw)
    }
}

extension SignalConstPointerBackupJsonExporter: SignalConstPointer {
    public func toOpaque() -> OpaquePointer? {
        self.raw
    }
}
