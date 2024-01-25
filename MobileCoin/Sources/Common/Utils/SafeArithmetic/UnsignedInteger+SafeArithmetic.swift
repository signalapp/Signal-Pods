//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension UnsignedInteger where Self: FixedWidthInteger {
    static func safeSum(values: [Self]) -> Self? {
        var accum: Self = 0
        for value in values {
            guard value <= Self.max - accum else {
                return nil
            }
            accum += value
        }
        return accum
    }
}

extension UnsignedInteger where Self: FixedWidthInteger {
    static func safeSubtract(
        value leftHandValue: Self,
        minusValue rightHandValue: Self
    ) -> Self? {
        guard leftHandValue >= rightHandValue else {
            return nil
        }
        return leftHandValue - rightHandValue
    }

    static func safeSubtract(
        sumOfValues leftHandValues: [Self],
        minusValue rightHandValue: Self
    ) -> Self? {
        var accumLeftHandValue: Self = 0
        var remainingRightHandValue = rightHandValue
        for leftHandValue in leftHandValues {
            var remainingLeftHandValue = leftHandValue

            let lesserValue = Swift.min(remainingLeftHandValue, remainingRightHandValue)
            remainingLeftHandValue -= lesserValue
            remainingRightHandValue -= lesserValue

            if remainingLeftHandValue > Self.max - accumLeftHandValue {
                return nil
            }
            accumLeftHandValue += remainingLeftHandValue
        }

        guard remainingRightHandValue == 0 else {
            return nil
        }

        return accumLeftHandValue
    }

    static func safeSubtract(
        sumOfValues leftHandValues: [Self],
        minusSumOfValues rightHandValues: [Self]
    ) -> Self? {
        var accumLeftHandValue: Self = 0
        var accumRightHandValue: Self = 0

        var remainingLeftHandValues = leftHandValues
        var remainingRightHandValues = rightHandValues

        while accumRightHandValue != 0 || !remainingRightHandValues.isEmpty {
            // Either accumLeftHandValue must be 0, accumRightHandValue must be 0, or they're both
            // 0. They can't both contain a positive value because of the subtraction below.
            if accumRightHandValue == 0 {
                // We know remainingRightHandValues is not empty at this point.
                accumRightHandValue = remainingRightHandValues.removeLast()
            } else {
                // Note: accumLeftHandValue is known to be 0 at this point.
                guard let leftHandValue = remainingLeftHandValues.popLast() else {
                    // We've exhausted the left-hand side, so we know we're going to be in the
                    // negative since accumLeftHandValue is 0 and accumRightHandValue is non-zero.
                    return nil
                }
                accumLeftHandValue = leftHandValue
            }

            // Ensure that at least 1 of the accumulators is 0.
            let lesserValue = Swift.min(accumLeftHandValue, accumRightHandValue)
            accumLeftHandValue -= lesserValue
            accumRightHandValue -= lesserValue
        }

        // We've exhausted the right-hand side, so let's sum the remaining left-hand values, making
        // sure it doesn't overflow.
        return safeSum(values: [accumLeftHandValue] + remainingLeftHandValues)
    }
}
