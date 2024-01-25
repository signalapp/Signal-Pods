//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

final class BlockchainMetaFetcher {
    private let inner: SerialDispatchLock<Inner>
    private let blockchainService: BlockchainService

    private let metaCacheTTL: TimeInterval

    init(
        blockchainService: BlockchainService,
        metaCacheTTL: TimeInterval,
        targetQueue: DispatchQueue?
    ) {
        self.inner = .init(Inner(), targetQueue: targetQueue)
        self.blockchainService = blockchainService
        self.metaCacheTTL = metaCacheTTL
    }

    func blockVersion(
        completion: @escaping (Result<BlockVersion, ConnectionError>) -> Void
    ) {
        getOrFetchBlockVersion {
            completion($0)
        }
    }

    func getCachedBlockVersion(
        completion: @escaping (BlockVersion?) -> Void
    ) {
        inner.accessAsync {
            completion($0.metaCache?.blockVersion)
        }
    }

    func cachedBlockVersion() -> BlockVersion? {
        inner.accessWithoutLocking.metaCache?.blockVersion
    }

    func feeStrategy(
        for feeLevel: FeeLevel,
        tokenId: TokenId,
        completion: @escaping (Result<FeeStrategy, ConnectionError>) -> Void
    ) {
        switch feeLevel {
        case .minimum:
            getOrFetchMinimumFee(tokenId: tokenId) {
                completion($0.map { fee in
                    FixedFeeStrategy(fee: fee)
                })
            }
        }
    }

    func cachedFee(tokenId: TokenId = .MOB) -> UInt64? {
        inner.accessWithoutLocking.metaCache?.minimumFees[tokenId]
    }

    func getOrFetchMinimumFee(
        tokenId: TokenId,
        completion: @escaping (Result<UInt64, ConnectionError>) -> Void
    ) {
        fetchCache {
            if let minimumFee = $0?.minimumFees[tokenId] {
                completion(.success(minimumFee))
            } else {
                self.fetchMeta {
                    completion($0.map { cache in
                        cache.minimumFees[tokenId] ?? McConstants.DEFAULT_MINIMUM_FEE
                    })
                }
            }
        }
    }

    func getCachedMinimumFee(
        tokenId: TokenId,
        completion: @escaping (UInt64?) -> Void
    ) {
        inner.accessAsync {
            completion($0.metaCache?.minimumFees[tokenId])
        }
    }

    func getOrFetchBlockVersion(
        completion: @escaping (Result<BlockVersion, ConnectionError>) -> Void
    ) {
        fetchCache {
            if let blockVersion = $0?.blockVersion {
                completion(.success(blockVersion))
            } else {
                self.fetchMeta {
                    completion($0.map { cache in
                        cache.blockVersion
                    })
                }
            }
        }
    }

    func fetchMeta(completion: @escaping (Result<MetaCache, ConnectionError>) -> Void) {
        blockchainService.getLastBlockInfo {
            switch $0 {
            case .success(let response):
                let responseFee = response.mobMinimumFee
                let minimumFee = responseFee != 0 ? responseFee : McConstants.DEFAULT_MINIMUM_FEE
                let blockVersion = BlockVersion(response.networkBlockVersion)
                let minimumFees = response.minimumFees.reduce(into: [TokenId: UInt64](), {
                    $0[TokenId($1.key)] = $1.value
                })
                self.cacheMeta(
                    minimumFee: minimumFee,
                    minimumFees: minimumFees,
                    blockVersion: blockVersion) {
                    completion(.success($0))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func resetCache(completion: @escaping () -> Void) {
        inner.accessAsync {
            $0.metaCache = nil
            completion()
        }
    }

    private func cacheMeta(
        minimumFee: UInt64,
        minimumFees: [TokenId: UInt64],
        blockVersion: BlockVersion,
        completion: @escaping (MetaCache) -> Void
    ) {
        inner.accessAsync {
            var minimumFees = minimumFees
            if minimumFees[.MOB] == nil || minimumFees[.MOB] == nil {
                minimumFees[.MOB] = minimumFee
            }
            let newMeta = MetaCache(
                minimumFees: minimumFees,
                blockVersion: blockVersion,
                fetchTimestamp: Date())

            $0.metaCache = newMeta
            completion(newMeta)
        }
    }

    private func fetchCache(completion: @escaping (MetaCache?) -> Void) {
        inner.accessAsync {
            if let metaCache = $0.metaCache,
               Date().timeIntervalSince(metaCache.fetchTimestamp) < self.metaCacheTTL
            {
                completion(metaCache)
            } else {
                completion(nil)
            }
        }
    }
}

extension BlockchainMetaFetcher {
    private struct Inner {
        var metaCache: MetaCache?
    }
}

extension BlockchainMetaFetcher {
    struct MetaCache {
        let minimumFees: [TokenId: UInt64]
        let blockVersion: BlockVersion
        let fetchTimestamp: Date
    }
}
