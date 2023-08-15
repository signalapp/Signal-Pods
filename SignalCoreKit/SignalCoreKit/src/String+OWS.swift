//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public extension NSString {
    func ows_truncated(toByteCount byteCount: UInt) -> NSString? {
        return (self as String).truncated(toByteCount: byteCount) as NSString?
    }
    
    @objc
    var ows_nilIfEmpty: NSString? {
        (length == 0) ? nil : self
    }
    
    @objc
    var ows_strippedOrNil: NSString? {
        ows_stripped().ows_nilIfEmpty
    }
}

// MARK: -

public extension String {
    var stripped: String {
        return (self as NSString).ows_stripped()
    }
    
    var strippedOrNil: String? {
        stripped.nilIfEmpty
    }
    
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var filterForDisplay: String {
        return (self as NSString).filterStringForDisplay()
    }

    // There appears to be a bug in NSBigMutableString that causes a
    // crash when using prefix to (not) truncate long strings to their
    // current length. safePrefix() avoids this crash by only using
    // prefix() if necessary.
    func safePrefix(_ maxLength: Int) -> String {
        guard maxLength < count else {
            return self
        }
        return String(prefix(maxLength))
    }

    // Truncates string to be less than or equal to byteCount, while ensuring we never truncate partial characters for multibyte characters.
    func truncated(toByteCount byteCount: UInt) -> String? {
        var lowerBoundCharCount = 0
        var upperBoundCharCount = self.count

        while (lowerBoundCharCount < upperBoundCharCount) {
            guard let upperBoundData = safePrefix(upperBoundCharCount).data(using: .utf8) else {
                owsFailDebug("upperBoundData was unexpectedly nil")
                return nil
            }

            if upperBoundData.count <= byteCount {
                break
            }

            // converge
            if upperBoundCharCount - lowerBoundCharCount == 1 {
                upperBoundCharCount = lowerBoundCharCount
                break
            }

            let midpointCharCount = (lowerBoundCharCount + upperBoundCharCount) / 2
            let midpointString = safePrefix(midpointCharCount)

            guard let midpointData = midpointString.data(using: .utf8) else {
                owsFailDebug("midpointData was unexpectedly nil")
                return nil
            }
            let midpointByteCount = midpointData.count

            if midpointByteCount < byteCount {
                lowerBoundCharCount = midpointCharCount
            } else {
                upperBoundCharCount = midpointCharCount
            }
        }

        return String(safePrefix(upperBoundCharCount))
    }

    func replaceCharacters(
        characterSet: CharacterSet,
        replacement: String
    ) -> String {
        let endIndex = self.endIndex
        var startIndex = self.startIndex

        // Build up a list of ranges that need to be replaced
        var ranges = [Range<String.Index>]()
        while startIndex < endIndex, let range = self.rangeOfCharacter(from: characterSet, options: [], range: startIndex..<endIndex) {
            ranges.append(range)
            startIndex = range.upperBound
        }

        // Don't do any allocation for unchanged strings
        guard ranges.count > 0 else { return self }

        // Create the result string and set up a capacity close to the final string
        var result = ""
        result.reserveCapacity(self.count)

        // Iterate through the ranges, appending the string between the last
        // match and the next, and then appending the replacement string
        var currentIndex = self.startIndex
        for range in ranges {
            result += self[currentIndex..<range.lowerBound]
            result += replacement
            currentIndex = range.upperBound
        }
        // Add the remainder of the string
        result += self[currentIndex..<endIndex]
        return result
    }

    func removeCharacters(characterSet: CharacterSet) -> String {
        return self.replaceCharacters(characterSet: characterSet, replacement: "")
    }
}

// MARK: -

extension Optional where Wrapped == String {
    public var isEmptyOrNil: Bool {
        guard let value = self else {
            return true
        }
        return value.isEmpty
    }
}
