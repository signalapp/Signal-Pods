//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

public enum ReceiptStatusCheckError: Error {
    case invalidReceipt(InvalidInputError)
    case connectionError(ConnectionError)
}

extension ReceiptStatusCheckError: CustomStringConvertible {
    public var description: String {
        "Receipt status check error: " + {
            switch self {
            case .invalidReceipt(let innerError):
                return "\(innerError)"
            case .connectionError(let innerError):
                return "\(innerError)"
            }
        }()
    }
}

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
        completion: @escaping (Result<ReceiptStatus, ReceiptStatusCheckError>) -> Void
    ) {
        checkReceivedStatus(receipt) {
            completion($0.map { ReceiptStatus($0) })
        }
    }

    func checkReceivedStatus(
        _ receipt: Receipt,
        completion: @escaping (Result<Receipt.ReceivedStatus, ReceiptStatusCheckError>) -> Void
    ) {
        switch cachedReceivedStatus(receipt) {
        case .success(let receivedStatus):
            if !receivedStatus.pending {
                serialQueue.async {
                    completion(.success(receivedStatus))
                }
            } else {
                balanceUpdater.updateBalance {
                    completion($0.mapError { .connectionError($0) }
                        .flatMap { _ in
                            self.cachedReceivedStatus(receipt)
                                .mapError { .invalidReceipt($0) }
                        })
                }
            }
        case .failure(let error):
            serialQueue.async {
                completion(.failure(.invalidReceipt(error)))
            }
        }
    }

    private func cachedReceivedStatus(_ receipt: Receipt)
        -> Result<Receipt.ReceivedStatus, InvalidInputError>
    {
        account.readSync { $0.cachedReceivedStatus(of: receipt) }
    }
}
