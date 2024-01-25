//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension UnsignedInteger {
    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isEqualToValue rightHandValue: Self
    ) -> Bool {
        var remainingRightHandValue = rightHandValue
        for leftHandValue in leftHandValues {
            if leftHandValue > remainingRightHandValue {
                return false
            }
            remainingRightHandValue -= leftHandValue
        }
        return remainingRightHandValue == 0
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isLessThanValue rightHandValue: Self
    ) -> Bool {
        var remainingRightHandValue = rightHandValue
        for leftHandValue in leftHandValues {
            if leftHandValue >= remainingRightHandValue {
                return false
            }
            remainingRightHandValue -= leftHandValue
        }
        return remainingRightHandValue > 0
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isLessThanOrEqualToValue rightHandValue: Self
    ) -> Bool {
        !safeCompare(sumOfValues: leftHandValues, isGreaterThanValue: rightHandValue)
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isGreaterThanValue rightHandValue: Self
    ) -> Bool {
        var remainingRightHandValue = rightHandValue
        for leftHandValue in leftHandValues {
            if leftHandValue > remainingRightHandValue {
                return true
            }
            remainingRightHandValue -= leftHandValue
        }
        return false
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isGreaterThanOrEqualToValue rightHandValue: Self
    ) -> Bool {
        !safeCompare(sumOfValues: leftHandValues, isLessThanValue: rightHandValue)
    }
}

extension UnsignedInteger {
    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isEqualToSumOfValues rightHandValues: [Self]
    ) -> Bool {
        var accumLeftHandValue: Self = 0
        var accumRightHandValue: Self = 0

        var remainingLeftHandValues = leftHandValues
        var remainingRightHandValues = rightHandValues

        while !remainingLeftHandValues.isEmpty || !remainingRightHandValues.isEmpty {
            // Either accumLeftHandValue must be 0, accumRightHandValue must be 0, or they're both
            // 0. They can't both be positive because of the subtraction below.
            if accumLeftHandValue == 0 {
                if let leftHandValue = remainingLeftHandValues.popLast() {
                    // Note: accumLeftHandValue is known to be 0 at this point.
                    accumLeftHandValue = leftHandValue
                } else {
                    // We've exhausted the left-hand side, so let's see if the remaining right-hand
                    // side contains only 0's.
                    return accumRightHandValue == 0
                        && remainingRightHandValues.allSatisfy { $0 == 0 }
                }
            } else {
                // Note: accumLeftHandValue > 0, accumRightHandValue == 0
                if let rightHandValue = remainingRightHandValues.popLast() {
                    // Note: accumRightHandValue is known to be 0 at this point.
                    accumRightHandValue = rightHandValue
                } else {
                    // We've exhausted the right-hand side and the left side > 0, so it can't be
                    // equal.
                    return false
                }
            }

            // Ensure that at least 1 of the accumulators is 0.
            let smallerValue = Swift.min(accumLeftHandValue, accumRightHandValue)
            accumLeftHandValue -= smallerValue
            accumRightHandValue -= smallerValue
        }

        return accumLeftHandValue == accumRightHandValue
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isLessThanSumOfValues rightHandValues: [Self]
    ) -> Bool {
        var accumLeftHandValue: Self = 0
        var accumRightHandValue: Self = 0

        var remainingLeftHandValues = leftHandValues
        var remainingRightHandValues = rightHandValues

        while !remainingLeftHandValues.isEmpty || !remainingRightHandValues.isEmpty {
            // Either accumLeftHandValue must be 0, accumRightHandValue must be 0, or they're both
            // 0. They can't both be positive because of the subtraction below.
            if accumRightHandValue == 0 {
                if let rightHandValue = remainingRightHandValues.popLast() {
                    // Note: accumRightHandValue is known to be 0 at this point.
                    accumRightHandValue = rightHandValue
                } else {
                    // We've exhausted the right-hand side, so we know it can't possibly be greater
                    // than the left.
                    return false
                }
            } else {
                // Note: accumRightHandValue > 0, accumLeftHandValue == 0
                if let leftHandValue = remainingLeftHandValues.popLast() {
                    // Note: accumLeftHandValue is known to be 0 at this point.
                    accumLeftHandValue = leftHandValue
                } else {
                    // We've exhausted the left-hand side and the right-hand side is non-zero, so we
                    // know the left-hand side must be less than the right.
                    return true
                }
            }

            // Ensure that at least 1 of the accumulators is 0.
            let smallerValue = Swift.min(accumLeftHandValue, accumRightHandValue)
            accumLeftHandValue -= smallerValue
            accumRightHandValue -= smallerValue
        }

        return accumLeftHandValue < accumRightHandValue
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isLessThanOrEqualToSumOfValues rightHandValues: [Self]
    ) -> Bool {
        !safeCompare(sumOfValues: leftHandValues, isGreaterThanSumOfValues: rightHandValues)
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isGreaterThanSumOfValues rightHandValues: [Self]
    ) -> Bool {
        var accumLeftHandValue: Self = 0
        var accumRightHandValue: Self = 0

        var remainingLeftHandValues = leftHandValues
        var remainingRightHandValues = rightHandValues

        while !remainingLeftHandValues.isEmpty || !remainingRightHandValues.isEmpty {
            // Either accumLeftHandValue must be 0, accumRightHandValue must be 0, or they're both
            // 0. They can't both contain a positive value because of the subtraction below.
            if accumLeftHandValue == 0 {
                if let leftHandValue = remainingLeftHandValues.popLast() {
                    // Note: accumLeftHandValue is known to be 0 at this point.
                    accumLeftHandValue = leftHandValue
                } else {
                    // We've exhausted the left-hand side, so we know it can't possibly be greater
                    // than the right.
                    return false
                }
            } else {
                // Note: accumLeftHandValue > 0, accumRightHandValue == 0
                if let rightHandValue = remainingRightHandValues.popLast() {
                    // Note: accumRightHandValue is known to be 0 at this point.
                    accumRightHandValue = rightHandValue
                } else {
                    // We've exhausted the right-hand side and the left-hand side is non-zero, so it
                    // must be greater than.
                    return true
                }
            }

            // Ensure that at least 1 of the accumulators is 0.
            let smallerValue = Swift.min(accumLeftHandValue, accumRightHandValue)
            accumLeftHandValue -= smallerValue
            accumRightHandValue -= smallerValue
        }

        return accumLeftHandValue > accumRightHandValue
    }

    static func safeCompare(
        sumOfValues leftHandValues: [Self],
        isGreaterThanOrEqualToSumOfValues rightHandValues: [Self]
    ) -> Bool {
        !safeCompare(sumOfValues: leftHandValues, isLessThanSumOfValues: rightHandValues)
    }
}
