//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_arguments multiline_function_chains

import Foundation
import LibMobileCoin

struct FogKeyImageChecker {
    private let serialQueue: DispatchQueue
    private let fogKeyImageService: FogKeyImageService

    init(fogKeyImageService: FogKeyImageService, targetQueue: DispatchQueue?) {
        logger.info("")
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.fogKeyImageService = fogKeyImageService
    }

    func checkKeyImage(
        keyImage: KeyImage,
        nextKeyImageQueryBlockIndex: UInt64 = 0,
        completion: @escaping (Result<KeyImage.SpentStatus, ConnectionError>) -> Void
    ) {
        logger.info("")
        checkKeyImages(
            keyImageQueries: [(keyImage, nextKeyImageQueryBlockIndex: nextKeyImageQueryBlockIndex)]
        ) {
            completion($0.flatMap { statuses in
                guard let keyImageStatus = statuses.first else {
                    return .failure(.invalidServerResponse(
                        "CheckKeyImage failed to return results: \(statuses)"))
                }
                return .success(keyImageStatus)
            })
        }
    }

    func checkKeyImages(
        keyImageQueries: [KeyImage],
        maxKeyImagesPerQuery: Int,
        completion: @escaping (Result<[KeyImage.SpentStatus], ConnectionError>) -> Void
    ) {
        logger.info("")
        checkKeyImages(
            keyImageQueries: keyImageQueries.map { ($0, nextKeyImageQueryBlockIndex: 0) },
            maxKeyImagesPerQuery: maxKeyImagesPerQuery,
            completion: completion)
    }

    func checkKeyImages(
        keyImageQueries: [(KeyImage, nextKeyImageQueryBlockIndex: UInt64)],
        maxKeyImagesPerQuery: Int,
        completion: @escaping (Result<[KeyImage.SpentStatus], ConnectionError>) -> Void
    ) {
        logger.info("")
        let queryArrays = keyImageQueries.chunked(maxLength: maxKeyImagesPerQuery).map { Array($0) }
        queryArrays.mapAsync({ chunk, callback in
            checkKeyImages(keyImageQueries: chunk, completion: callback)
        }, serialQueue: serialQueue, completion: { result in
            completion(result.map { $0.flatMap { $0 } })
        })
    }

    func checkKeyImages(
        keyImageQueries: [KeyImage],
        completion: @escaping (Result<[KeyImage.SpentStatus], ConnectionError>) -> Void
    ) {
        logger.info("")
        checkKeyImages(
            keyImageQueries: keyImageQueries.map { ($0, nextKeyImageQueryBlockIndex: 0) },
            completion: completion)
    }

    func checkKeyImages(
        keyImageQueries: [(KeyImage, nextKeyImageQueryBlockIndex: UInt64)],
        completion: @escaping (Result<[KeyImage.SpentStatus], ConnectionError>) -> Void
    ) {
        logger.info("")
        var request = FogLedger_CheckKeyImagesRequest()
        request.queries = keyImageQueries.map {
            var query = FogLedger_KeyImageQuery()
            query.keyImage = External_KeyImage($0.0)
            query.startBlock = $0.nextKeyImageQueryBlockIndex
            return query
        }
        fogKeyImageService.checkKeyImages(request: request) {
            completion($0.flatMap {
                Self.parseResponse(keyImageQueries: keyImageQueries, response: $0)
            })
        }
    }

    private static func parseResponse(
        keyImageQueries: [(KeyImage, nextKeyImageQueryBlockIndex: UInt64)],
        response: FogLedger_CheckKeyImagesResponse
    ) -> Result<[KeyImage.SpentStatus], ConnectionError> {
        keyImageQueries.map { query in
            guard let keyImageResult = response.results.first(
                where: { KeyImage($0.keyImage) == query.0 }) else
            {
                return .success(.unspent(knownToBeUnspentBlockCount: response.numBlocks))
            }

            switch keyImageResult.keyImageResultCodeEnum {
            case .spent:
                let spentAtBlock = BlockMetadata(
                    index: keyImageResult.spentAt,
                    timestampStatus: keyImageResult.timestampStatus)
                return .success(.spent(block: spentAtBlock))
            case .notSpent:
                return .success(.unspent(knownToBeUnspentBlockCount: response.numBlocks))
            case .keyImageError, .unused, .UNRECOGNIZED:
                return .failure(.invalidServerResponse("Fog KeyImage result error: " +
                    "\(keyImageResult.keyImageResultCodeEnum), response: \(response)"))
            }
        }.collectResult()
    }
}
