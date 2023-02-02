//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

// swiftlint:disable unavailable_function
public class MobileCoinRng: RandomNumberGenerator {
    public func next() -> UInt64 {
        fatalError("Subclass must override")
    }
}

extension MobileCoinRng {
    func generateRngSeed() -> RngSeed? {
        RngSeed(Array(0..<4)
            .map { _ in
                self.next()
            }
            .reduce(Data(), { ongoing, next in
                    let data = Data(from: next)
                    return ongoing + data
            })
        )
    }
}

public struct RngSeed {
    private(set) var data: Data32

    public init?(_ data: Data) {
        guard let data = Data32(data) else {
            return nil
        }
        self.data = data
    }

    public init() {
        guard let data = Data32(.secRngGenBytes(32)) else {
            fatalError(".secRngGenBytes(32) should always create a valid Data32")
        }
        self.data = data
    }
}
