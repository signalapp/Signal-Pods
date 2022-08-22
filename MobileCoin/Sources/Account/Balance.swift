//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public struct Balance {
    public let amountLow: UInt64
    public let amountHigh: UInt64

    @available(*, deprecated, message: "Use the new SI prefix & token agnostic `.amountLow`")
    public var amountPicoMobLow: UInt64 { amountLow }

    @available(*, deprecated, message: "Use the new SI prefix & token agnostic `.amountHigh`")
    public var amountPicoMobHigh: UInt64 { amountHigh }

    public let tokenId: TokenId
    let blockCount: UInt64

    init(values: [UInt64], blockCount: UInt64, tokenId: TokenId) {
        var amountLow: UInt64 = 0
        var amountHigh: UInt64 = 0
        for value in values {
            let (partialValue, overflow) = amountLow.addingReportingOverflow(value)
            amountLow = partialValue
            if overflow {
                amountHigh += 1
            }
        }
        self.init(
            amountLow: amountLow,
            amountHigh: amountHigh,
            blockCount: blockCount,
            tokenId: tokenId)
    }

    init(amountLow: UInt64, amountHigh: UInt64, blockCount: UInt64, tokenId: TokenId) {
        self.amountLow = amountLow
        self.amountHigh = amountHigh
        self.blockCount = blockCount
        self.tokenId = tokenId
    }

    /// - Returns: `nil` when the amount is too large to fit in a `UInt64`.
    @available(*, deprecated, message: "Use the new SI prefix & token agnostic `.amount()`")
    public func amountPicoMob() -> UInt64? {
        guard amountHigh == 0 else {
            return nil
        }
        return amountLow
    }

    public func amount() -> UInt64? {
        guard amountHigh == 0 else {
            return nil
        }
        return amountLow
    }

    @available(*, deprecated, message: "Use the new token agnostic `.amountParts`")
    public var amountMobParts: (mobInt: UInt64, picoFrac: UInt64) {
        (mobInt: amountParts.int, picoFrac: amountParts.frac)
    }

    /// Convenience accessor for balance value. `int` is the integer part of the value when
    /// represented in `.tokenId`. `frac` is the fractional part of the value when represented in 
    /// `.tokenId`. However, rather than reprenting the fractional part as a decimal fraction,
    /// it is represented in the tokens fundamental unit. MOB uses 12 significant digits so its
    /// fundamental unit is a picoMOB, thus allowing both parts to be integer values.
    ///
    /// The purpose of this representation is to facilitate presenting the balance to the user in
    /// a readable form for each token.
    ///
    /// To illustrate, given an amount in the form of XXXXXXXXX.YYYYYYYYYYYY MOB,
    /// - `int`: XXXXXXXXX (denominated in MOB)
    /// - `frac`: YYYYYYYYYYYY (denominated in picoMOB)
    ///
    /// It is necessary to break apart the values into 2 parts because the total max possible
    /// balance is too large to fit in a single `UInt64`, when denominated in picoMOB, assuming 250
    /// million MOB in circulation and assuming a base unit of 1 picoMOB as the smallest indivisible
    /// unit of MOB.
    public var amountParts: (int: UInt64, frac: UInt64) {
        //
        // >> Example math with significantDigits == 12 (MOB)
        //
        // amount (picoMOB) = amountLow + amountHigh * 2^64
        //
        // >> Now expand amountLow & amountHigh to "decimal" numbers
        //
        // amountLowMobDec = amountLow / 10^12
        // amountHighMobDec = amountHigh * 2^64 / 10^12
        //
        // >> where 10^12 is 10^(significantDigits)
        //
        // amountMobDec = amountLowMobDec + amountHighMobDec
        //
        // >> Now expand amountLowDec & amountHighDec to their Integer & Fractional parts
        //
        // >> amountLowDec = amountLowMobInt.amountLowPicoFrac
        //
        // amountLowMobInt = floor(amountLow / 10^12)
        // amountLowPicoFrac = amountLow % 10^12
        //
        // >> amountHighDec = amountHighMobInt.amountHighPicoFrac
        //
        // amountHighMobInt = floor((amountHigh * 2^64) / 10^12)
        //
        //                  >> factor out common 2^12 for now
        //                  = floor((amountHigh * (2^52 * 2^12)) / (5^12 * 2^12)
        //
        //                  >> bitshift by 52 (same as multiply by 2^52)
        //                  >> ... and bitshift number == (64 - significantDigits)
        //                  = floor((amountHigh << 52) / 5^12)
        //
        // amountHighPicoFrac = (amountHigh * 2^64) % 10^12
        //
        //                  >> re-apply the 2^12
        //                  = ((amountHigh << 52) % 5^12) << 12
        //
        // amountPicoFracCarry = floor((amountLowPicoFrac + amountHighPicoFrac) / 10^12)
        //
        // amountMobInt = amountLowMobInt + amountHighMobInt + amountPicoFracCarry
        // amountPicoFrac = (amountLowPicoFrac + amountHighPicoFrac) % 10^12

        let significantDigits = tokenId.significantDigits

        let divideBy = UInt64(pow(Double(10), Double(significantDigits)))
        let (amountLowInt, amountLowFrac) = { () -> (UInt64, UInt64) in
            let parts = amountLow.quotientAndRemainder(dividingBy: divideBy)
            return (UInt64(parts.quotient), parts.remainder)
        }()

        let (amountHighInt, amountHighFrac) = { () -> (UInt64, UInt64) in
            let amountHighIntermediary = UInt64(amountHigh) << (64 - significantDigits)
            let factored = UInt64(pow(Double(5), Double(significantDigits)))
            let parts = amountHighIntermediary.quotientAndRemainder(dividingBy: factored)
            return (UInt64(parts.quotient), parts.remainder << significantDigits)
        }()

        let amountFracParts = (amountLowFrac + amountHighFrac).quotientAndRemainder(
            dividingBy: divideBy)

        let amountInt = amountLowInt + amountHighInt + UInt64(amountFracParts.quotient)
        let amountFrac = amountFracParts.remainder

        return (amountInt, amountFrac)
    }
}

extension Balance: Equatable {}
extension Balance: Hashable {}

extension Balance: CustomStringConvertible {
    public var description: String {
        let amount = amountParts
        return String(
                format: "%llu.%0\(tokenId.significantDigits)llu \(tokenId.name)",
                amount.int,
                amount.frac)
    }
}

enum SIDecimalPrefix: UInt8 {
    case deci = 1
    case centi = 2
    case milli = 3
    case micro = 6
    case nano = 9
    case pico = 12
    case femto = 15
    case atto = 18
    case zepto = 21
    case yocto = 24
}

extension SIDecimalPrefix {
    var name: String { String(describing: self) }
}
