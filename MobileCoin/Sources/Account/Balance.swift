//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct Balance {
    public let amountPicoMobLow: UInt64
    public let amountPicoMobHigh: UInt8
    let blockCount: UInt64

    init(values: [UInt64], blockCount: UInt64) {
        logger.info("values: \(redacting: values), blockCount: \(blockCount)")
        var amountLow: UInt64 = 0
        var amountHigh: UInt8 = 0
        for value in values {
            let (partialValue, overflow) = amountLow.addingReportingOverflow(value)
            amountLow = partialValue
            if overflow {
                amountHigh += 1
            }
        }
        self.init(amountLow: amountLow, amountHigh: amountHigh, blockCount: blockCount)
    }

    init(amountLow: UInt64, amountHigh: UInt8, blockCount: UInt64) {
        self.amountPicoMobLow = amountLow
        self.amountPicoMobHigh = amountHigh
        self.blockCount = blockCount
    }

    /// - Returns: `nil` when the amount is too large to fit in a `UInt64`.
    public func amountPicoMob() -> UInt64? {
        guard amountPicoMobHigh == 0 else {
            return nil
        }
        return amountPicoMobLow
    }

    /// Convenience accessor for balance value. `mobInt` is the integer part of the value when
    /// represented in MOB. `picoFrac` is the fractional part of the value when represented in MOB.
    /// However, rather than reprenting the fractional part as a decimal fraction, it is represented
    /// in picoMOB, thus allowing both parts to be integer values.
    ///
    /// The purpose of this representation is to facilitate presenting the balance to the user in
    /// MOB form.
    ///
    /// To illustrate, given an amount in the form of XXXXXXXXX.YYYYYYYYYYYY MOB,
    /// - `mobInt`: XXXXXXXXX (denominated in MOB)
    /// - `picoFrac`: YYYYYYYYYYYY (denominated in picoMOB)
    ///
    /// It is necessary to break apart the values into 2 parts because the total max possible
    /// balance is too large to fit in a single `UInt64`, when denominated in picoMOB, assuming 250
    /// million MOB in circulation and assuming a base unit of 1 picoMOB as the smallest indivisible
    /// unit of MOB.
    public var amountMobParts: (mobInt: UInt32, picoFrac: UInt64) {
        // amount (picoMOB) = amountLow + amountHigh * 2^64
        //
        // amountLowMobDec = amountLow / 10^12
        // amountHighMobDec = amountHigh * 2^64 / 10^12
        //
        // amountMobDec = amountLowMobDec + amountHighMobDec
        //
        // amountLowMobInt = floor(amountLow / 10^12)
        // amountLowPicoFrac = amountLow % 10^12

        // amountHighMobInt = floor((amountHigh * 2^64) / 10^12)
        //                  = floor((amountHigh << 52) / 5^12)
        // amountHighPicoFrac = (amountHigh * 2^64) % 10^12
        //                   = ((amountHigh << 52) % 5^12) << 12
        //
        // amountPicoFracCarry = floor((amountLowPicoFrac + amountHighPicoFrac) / 10^12)
        //
        // amountMobInt = amountLowMobInt + amountHighMobInt + amountPicoFracCarry
        // amountPicoFrac = (amountLowPicoFrac + amountHighPicoFrac) % 10^12

        let (amountLowMobInt, amountLowPicoFrac) = { () -> (UInt32, UInt64) in
            // 10^12 = 1_000_000_000_000
            let mobParts = amountPicoMobLow.quotientAndRemainder(dividingBy: 1_000_000_000_000)
            return (UInt32(mobParts.quotient), mobParts.remainder)
        }()

        let (amountHighMobInt, amountHighPicoFrac) = { () -> (UInt32, UInt64) in
            // Intermediary = base of 5^-12 MOB
            let amountHighIntermediary = UInt64(amountPicoMobHigh) << 52
            // 5^12 = 244_140_625
            let mobParts = amountHighIntermediary.quotientAndRemainder(dividingBy: 244_140_625)
            return (UInt32(mobParts.quotient), mobParts.remainder << 12)
        }()

        let amountPicoFracParts = (amountLowPicoFrac + amountHighPicoFrac).quotientAndRemainder(
            dividingBy: 1_000_000_000_000)

        let amountMobInt = amountLowMobInt + amountHighMobInt + UInt32(amountPicoFracParts.quotient)
        let amountPicoFrac = amountPicoFracParts.remainder

        return (amountMobInt, amountPicoFrac)
    }
}

extension Balance: Equatable {}
extension Balance: Hashable {}

extension Balance: CustomStringConvertible {
    public var description: String {
        let amountMob = amountMobParts
        return String(format: "%u.%012llu MOB", amountMob.mobInt, amountMob.picoFrac)
    }
}
