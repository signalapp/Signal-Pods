//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class DefaultMixinSelectionStrategy: MixinSelectionStrategy {
    let offsetParam: UInt64 = 88
    var rng: RandomNumberGenerator = SystemRandomNumberGenerator()

    // Selection window: [t-k, t+k] where t = real txo index, k = offsetParam
    var selectionWindowWidth: UInt64 {
        2 * offsetParam + 1
    }

    func selectMixinIndices(
        forRealTxOutIndices realTxOutIndices: [UInt64],
        selectionRange: PartialRangeUpTo<UInt64>?,
        excludedTxOutIndices: [UInt64],
        ringSize: Int
    ) -> [Set<UInt64>] {
        // Ensure selectionRange width is at least as large as the intended selection window width,
        // otherwise disable selectionRange.
        let selectionRange =
            selectionRange.flatMap { $0.upperBound >= selectionWindowWidth ? $0 : nil }

        var excludedIndices = Set<UInt64>(
            minimumCapacity: excludedTxOutIndices.count + ringSize * realTxOutIndices.count)
        excludedIndices.formUnion(excludedTxOutIndices)
        excludedIndices.formUnion(realTxOutIndices)

        return realTxOutIndices.map { realTxOutIndex in
            let selectionWindowMidpoint = safeSelectMidpoint(
                sourceIndex: realTxOutIndex,
                selectionRange: selectionRange)
            let selectionWindowLowerBound = selectionWindowMidpoint - offsetParam

            var selectedIndices = Set<UInt64>(minimumCapacity: ringSize)
            selectedIndices.insert(realTxOutIndex)

            while selectedIndices.count < ringSize {
                let selectedIndex = selectIndex(lowerBound: selectionWindowLowerBound)

                guard !excludedIndices.contains(selectedIndex) else {
                    continue
                }

                selectedIndices.insert(selectedIndex)
                excludedIndices.insert(selectedIndex)
            }

            return selectedIndices
        }
    }

    /// Selects a random midpoint from a midpoint selection window, centered around sourceIndex.
    ///
    /// Midpoint selection window is [t-k, t+k], centered around sourceIndex,
    /// where t = sourceIndex, k = offsetParam
    ///
    /// Index selection window is [m-k, m+k], centered around midpoint, where m = midpoint
    ///
    /// Ensures lower bound of index selection window is at least 0.
    /// Ensures upper bound of index selection window is less than selectionRange.upperBound, if
    /// selectionRange is provided.
    private func safeSelectMidpoint(
        sourceIndex: UInt64,
        selectionRange: PartialRangeUpTo<UInt64>?
    ) -> UInt64 {
        // Midpoint = sourceIndex + [0, 2 * offsetParam + 1).random - offsetParam

        // Add up positive components of midpoint.
        var midpoint = sourceIndex + rng.next(upperBound: selectionWindowWidth)
        // Safely subtract half the width of the selection window, ensuring that the lower bound of
        // the index selection window is at least 0.
        midpoint = midpoint >= 2 * offsetParam ? midpoint - offsetParam : offsetParam

        if let selectionRange = selectionRange {
            // Ensure upper bound of index selection window is less than selectionRange.upperBound
            if midpoint + offsetParam + 1 >= selectionRange.upperBound {
                midpoint = selectionRange.upperBound - (offsetParam + 1)
            }
        }

        return midpoint
    }

    private func selectIndex(lowerBound: UInt64) -> UInt64 {
        lowerBound + rng.next(upperBound: selectionWindowWidth)
    }
}
