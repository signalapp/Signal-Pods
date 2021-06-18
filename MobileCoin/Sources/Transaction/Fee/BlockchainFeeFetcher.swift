//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class BlockchainFeeFetcher {
    private let inner: SerialDispatchLock<Inner>
    private let blockchainService: BlockchainService

    private let minimumFeeCacheTTL: TimeInterval

    init(
        blockchainService: BlockchainService,
        minimumFeeCacheTTL: TimeInterval,
        targetQueue: DispatchQueue?
    ) {
        self.inner = .init(Inner(), targetQueue: targetQueue)
        self.blockchainService = blockchainService
        self.minimumFeeCacheTTL = minimumFeeCacheTTL
    }

    func feeStrategy(
        for feeLevel: FeeLevel,
        completion: @escaping (Result<FeeStrategy, ConnectionError>) -> Void
    ) {
        switch feeLevel {
        case .minimum:
            getOrFetchMinimumFee {
                completion($0.map { fee in
                    FixedFeeStrategy(fee: fee)
                })
            }
        }
    }

    func getOrFetchMinimumFee(completion: @escaping (Result<UInt64, ConnectionError>) -> Void) {
        fetchCache {
            if let minimumFee = $0 {
                completion(.success(minimumFee))
            } else {
                self.fetchMinimumFee(completion: completion)
            }
        }
    }

    func fetchMinimumFee(completion: @escaping (Result<UInt64, ConnectionError>) -> Void) {
        blockchainService.getLastBlockInfo {
            switch $0 {
            case .success(let response):
                let responseFee = response.minimumFee
                let minimumFee = responseFee != 0 ? responseFee : McConstants.DEFAULT_MINIMUM_FEE
                self.cacheMinimumFee(minimumFee) {
                    completion(.success(minimumFee))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func resetCache(completion: @escaping () -> Void) {
        inner.accessAsync {
            $0.minimumFeeCache = nil
            completion()
        }
    }

    private func cacheMinimumFee(_ minimumFee: UInt64, completion: @escaping () -> Void) {
        inner.accessAsync {
            $0.minimumFeeCache = MinimumFeeCache(minimumFee: minimumFee, fetchTimestamp: Date())
            completion()
        }
    }

    private func fetchCache(completion: @escaping (UInt64?) -> Void) {
        inner.accessAsync {
            if let minimumFeeCache = $0.minimumFeeCache,
               Date().timeIntervalSince(minimumFeeCache.fetchTimestamp) < self.minimumFeeCacheTTL
            {
                completion(minimumFeeCache.minimumFee)
            } else {
                completion(nil)
            }
        }
    }
}

extension BlockchainFeeFetcher {
    private struct Inner {
        var minimumFeeCache: MinimumFeeCache?
    }
}

extension BlockchainFeeFetcher {
    private struct MinimumFeeCache {
        let minimumFee: UInt64
        let fetchTimestamp: Date
    }
}
