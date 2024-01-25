//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_arguments multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct FogKeyImageChecker {
    private let serialQueue: DispatchQueue
    private let fogKeyImageService: FogKeyImageService
    private let syncCheckerLock: ReadWriteDispatchLock<FogSyncCheckable>

    init(
        fogKeyImageService: FogKeyImageService,
        targetQueue: DispatchQueue?,
        syncChecker: ReadWriteDispatchLock<FogSyncCheckable>
    ) {
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.fogKeyImageService = fogKeyImageService
        self.syncCheckerLock = syncChecker
    }

    func checkKeyImage(
        keyImage: KeyImage,
        nextKeyImageQueryBlockIndex: UInt64 = 0,
        completion: @escaping (Result<KeyImage.SpentStatus, ConnectionError>) -> Void
    ) {
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
        checkKeyImages(
            keyImageQueries: keyImageQueries.map { ($0, nextKeyImageQueryBlockIndex: 0) },
            completion: completion)
    }

    func checkKeyImages(
        keyImageQueries: [(KeyImage, nextKeyImageQueryBlockIndex: UInt64)],
        completion: @escaping (Result<[KeyImage.SpentStatus], ConnectionError>) -> Void
    ) {
        var request = FogLedger_CheckKeyImagesRequest()
        request.queries = keyImageQueries.map {
            var query = FogLedger_KeyImageQuery()
            query.keyImage = External_KeyImage($0.0)
            query.startBlock = $0.nextKeyImageQueryBlockIndex
            return query
        }
        fogKeyImageService.checkKeyImages(request: request) { response in
            if let result = try? response.get() {
                self.syncCheckerLock.writeSync({
                    $0.setLedgersHighestKnownBlock(result.numBlocks)
                })
            }
            completion(response.flatMap {
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
