//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_arguments

import Foundation
import LibMobileCoin

struct FogKeyImageChecker {
    private let serialQueue: DispatchQueue
    private let fogKeyImageService: FogKeyImageService

    init(fogKeyImageService: FogKeyImageService, targetQueue: DispatchQueue?) {
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.fogKeyImageService = fogKeyImageService
    }

    func checkInputKeyImages(
        for transaction: Transaction,
        completion: @escaping (Result<KeyImage.SpentStatus, Error>) -> Void
    ) {
        do {
            guard let keyImage = transaction.inputKeyImagesTyped.first else {
                throw MalformedInput("transaction has no inputs: \(transaction)")
            }

            checkKeyImages(
                keyImageQueries: [(keyImage, nextKeyImageQueryBlockIndex:0)],
                maxKeyImagesPerQuery: 10
            ) {
                completion($0.flatMap { statuses in
                    guard let keyImageStatus = statuses.first else {
                        throw ConnectionFailure("CheckKeyImage failed to return results: " +
                            "\(statuses)")
                    }
                    return keyImageStatus
                })
            }
        } catch {
            serialQueue.async {
                completion(.failure(error))
            }
        }
    }

    func checkKeyImages(
        keyImageQueries: [(KeyImage, nextKeyImageQueryBlockIndex: UInt64)],
        maxKeyImagesPerQuery: Int,
        completion: @escaping (Result<[KeyImage.SpentStatus], Error>) -> Void
    ) {
        let queryArrays = keyImageQueries.chunked(maxLength: maxKeyImagesPerQuery).map { Array($0) }
        queryArrays.mapAsync({ chunk, callback in
            checkKeyImages(keyImageQueries: chunk, completion: callback)
        }, serialQueue: serialQueue, completion: { result in
            completion(result.map { $0.flatMap { $0 } })
        })
    }

    func checkKeyImages(
        keyImageQueries: [(KeyImage, nextKeyImageQueryBlockIndex: UInt64)],
        completion: @escaping (Result<[KeyImage.SpentStatus], Error>) -> Void
    ) {
        var request = FogLedger_CheckKeyImagesRequest()
        request.queries = keyImageQueries.map {
            var query = FogLedger_KeyImageQuery()
            query.keyImage = External_KeyImage($0.0)
            query.startBlock = $0.nextKeyImageQueryBlockIndex
            return query
        }
        fogKeyImageService.checkKeyImages(request: request) {
            completion($0.flatMap { response in
                let statuses: [KeyImage.SpentStatus] = try keyImageQueries.map { query in
                    guard let keyImageResult = response.results.first(
                        where: { KeyImage($0.keyImage) == query.0 }) else
                    {
                        return .unspent(knownToBeUnspentBlockCount: response.numBlocks)
                    }

                    switch keyImageResult.keyImageResultCodeEnum {
                    case .spent:
                        let spentAtBlock = BlockMetadata(
                            index: keyImageResult.spentAt,
                            timestampStatus: keyImageResult.timestampStatus)
                        return .spent(block: spentAtBlock)
                    case .notSpent:
                        return .unspent(knownToBeUnspentBlockCount: response.numBlocks)
                    case .keyImageError, .unused, .UNRECOGNIZED:
                        throw ConnectionFailure("Fog KeyImage result error: " +
                            "\(keyImageResult.keyImageResultCodeEnum), " +
                            "response: \(response)")
                    }
                }
                return statuses
            })
        }
    }
}
