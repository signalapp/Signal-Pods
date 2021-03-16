//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol DataConvertible: Hashable, DataProtocol, ContiguousBytes {
    init?(_ data: Data)

    var data: Data { get }
}

protocol DataConvertibleImpl: DataConvertible, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable, Codable
where Self.Iterator == Data.Iterator, Self.SubSequence == Data, Self.Indices == Range<Int>,
    Self.Regions == CollectionOfOne<Data>
{
    associatedtype Iterator = Data.Iterator
    associatedtype SubSequence = Data
}

// MARK: - Data

extension DataConvertibleImpl {
    /// Initialize with the contents of a `URL`.
    ///
    /// - parameter url: The `URL` to read.
    /// - parameter options: Options for the read operation. Default value is `[]`.
    /// - throws: An error in the Cocoa domain, if `url` cannot be read.
    init?(contentsOf url: URL, options: Data.ReadingOptions = []) throws {
        self.init(try Data(contentsOf: url, options: options))
    }
    /// Initialize from a Base-64 encoded String using the given options.
    ///
    /// Returns nil when the input is not recognized as valid Base-64.
    /// - parameter base64String: The string to parse.
    /// - parameter options: Encoding options. Default value is `[]`.
    init?(base64Encoded base64String: String, options: Data.Base64DecodingOptions = []) {
        guard let data = Data(base64Encoded: base64String, options: options) else {
            return nil
        }
        self.init(data)
    }

    /// Initialize from a Base-64, UTF-8 encoded `Data`.
    ///
    /// Returns nil when the input is not recognized as valid Base-64.
    ///
    /// - parameter base64Data: Base-64, UTF-8 encoded input data.
    /// - parameter options: Decoding options. Default value is `[]`.
    init?(base64Encoded base64Data: Data, options: Data.Base64DecodingOptions = []) {
        guard let data = Data(base64Encoded: base64Data, options: options) else {
            return nil
        }
        self.init(data)
    }

    /// Initialize with the elements of a `UInt8` sequence.
    ///
    /// - Parameter elements: The sequence of elements for the new collection.
    ///   `elements` must be finite.
    init?<S: Sequence>(_ elements: S) where S.Element == UInt8 {
        self.init(Data(elements))
    }

    /// Returns a Base-64 encoded string.
    ///
    /// - parameter options: The options to use for the encoding. Default value is `[]`.
    /// - returns: The Base-64 encoded string.
    func base64EncodedString(options: Data.Base64EncodingOptions = []) -> String {
        data.base64EncodedString(options: options)
    }

    /// Returns a Base-64 encoded `Data`.
    ///
    /// - parameter options: The options to use for the encoding. Default value is `[]`.
    /// - returns: The Base-64 encoded data.
    func base64EncodedData(options: Data.Base64EncodingOptions = []) -> Data {
        data.base64EncodedData(options: options)
    }
}

// MARK: - Sequence

extension DataConvertibleImpl {
    /// An iterator over the contents of the data.
    ///
    /// The iterator will increment byte-by-byte.
    func makeIterator() -> Data.Iterator {
        data.makeIterator()
    }
}

// MARK: - Collection

extension DataConvertibleImpl {
    /// The number of bytes in the data.
    var count: Int { data.count }

    /// Returns the byte at the specified index.
    subscript(index: Index) -> UInt8 { data[index] }

    subscript(bounds: Range<Index>) -> Data { data[bounds] }

    /// The start `Index` in the data.
    var startIndex: Index { data.startIndex }

    /// The end `Index` into the data.
    ///
    /// This is the "one-past-the-end" position, and will always be equal to the `count`.
    var endIndex: Index { data.endIndex }

    var indices: Range<Int> { data.indices }
}

// MARK: - BidirectionalCollection

extension DataConvertibleImpl {
    func index(before i: Index) -> Index {
        data.index(before: i)
    }

    func index(after i: Index) -> Index {
        data.index(after: i)
    }
}

// MARK: - DataProtocol

extension DataConvertibleImpl {
    var regions: CollectionOfOne<Data> { data.regions }
}

// MARK: - ContiguousBytes

extension DataConvertibleImpl {
    func withUnsafeBytes<ResultType>(_ body: (UnsafeRawBufferPointer) throws -> ResultType) rethrows
        -> ResultType
    {
        try data.withUnsafeBytes(body)
    }
}

// MARK: - CustomStringConvertible

extension DataConvertibleImpl {
    /// A human-readable description for the data.
    var description: String { data.description }
}

// MARK: - CustomDebugStringConvertible

extension DataConvertibleImpl {
    /// A human-readable debug description for the data.
    var debugDescription: String { data.debugDescription }
}

// MARK: - CustomReflectable

extension DataConvertibleImpl {
    /// The custom mirror for this instance.
    ///
    /// If this type has value semantics, the mirror should be unaffected by
    /// subsequent mutations of the instance.
    var customMirror: Mirror { data.customMirror }
}

// MARK: - Hashable

extension DataConvertibleImpl {
    func hash(into hasher: inout Hasher) {
        data.hash(into: &hasher)
    }
}

// MARK: - Codable

extension DataConvertibleImpl {
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let data = try Data(from: decoder)
        guard let decoded = Self(data) else {
            throw InvalidInputError("Data validation failed.")
        }
        self = decoded
    }

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        try data.encode(to: encoder)
    }
}
