//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable todo

import Foundation

struct FeeCalculator {
    private let serialQueue: DispatchQueue

    init(targetQueue: DispatchQueue?) {
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
    }

    func minimumFee(amount: UInt64, completion: @escaping (Result<UInt64, ConnectionError>) -> Void)
    {
        // TODO: Throw error if defragmentation is needed
        serialQueue.async {
            completion(.success(McConstants.MINIMUM_FEE))
        }
    }

    func baseFee(amount: UInt64, completion: @escaping (Result<UInt64, ConnectionError>) -> Void) {
        minimumFee(amount: amount) { completion($0.map { 2 * $0 }) }
    }

    func priorityFee(
        amount: UInt64,
        completion: @escaping (Result<UInt64, ConnectionError>) -> Void
    ) {
        minimumFee(amount: amount) { completion($0.map { 3 * $0 }) }
    }
}
