//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public extension NSString {
    func ows_truncated(toByteCount byteCount: UInt) -> NSString? {
        return (self as String).truncated(toByteCount: byteCount) as NSString?
    }
}

public extension String {
    var stripped: String {
        return (self as NSString).ows_stripped()
    }

    var filterForDisplay: String? {
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

    func replaceCharacters(characterSet: CharacterSet, replacement: String) -> String {
        let components = self.components(separatedBy: characterSet)
        return components.joined(separator: replacement)
    }

    func removeCharacters(characterSet: CharacterSet) -> String {
        let components = self.components(separatedBy: characterSet)
        return components.joined()
    }
}
