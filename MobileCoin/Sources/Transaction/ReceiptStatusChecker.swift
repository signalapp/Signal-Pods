//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

struct ReceiptStatusChecker {
    private let account: ReadWriteDispatchLock<Account>
    private let balanceUpdater: Account.BalanceUpdater
    private let serialQueue: DispatchQueue

    init(
        account: ReadWriteDispatchLock<Account>,
        fogViewService: FogViewService,
        fogKeyImageService: FogKeyImageService,
        fogBlockService: FogBlockService,
        fogQueryScalingStrategy: FogQueryScalingStrategy,
        targetQueue: DispatchQueue?
    ) {
        self.account = account
        self.balanceUpdater = Account.BalanceUpdater(
            account: account,
            fogViewService: fogViewService,
            fogKeyImageService: fogKeyImageService,
            fogBlockService: fogBlockService,
            fogQueryScalingStrategy: fogQueryScalingStrategy,
            targetQueue: targetQueue)
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
    }

    func checkStatus(
        _ receipt: Receipt,
        completion: @escaping (Result<ReceiptStatus, Error>) -> Void
    ) {
        checkReceivedStatus(receipt) {
            completion($0.map { ReceiptStatus($0) })
        }
    }

    func checkReceivedStatus(
        _ receipt: Receipt,
        completion: @escaping (Result<Receipt.ReceivedStatus, Error>) -> Void
    ) {
        do {
            let receivedStatus = try cachedReceivedStatus(receipt)
            if !receivedStatus.pending {
                serialQueue.async {
                    completion(.success(receivedStatus))
                }
            } else {
                balanceUpdater.updateBalance {
                    completion($0.flatMap { _ in
                        try self.cachedReceivedStatus(receipt)
                    })
                }
            }
        } catch {
            serialQueue.async {
                completion(.failure(error))
            }
        }
    }

    private func cachedReceivedStatus(_ receipt: Receipt) throws -> Receipt.ReceivedStatus {
        try account.readSync { try $0.cachedReceivedStatus(of: receipt) }
    }
}
