//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_arguments

import Foundation
import LibMobileCoin

struct FogMerkleProofFetcher {
    private let serialQueue: DispatchQueue
    private let fogMerkleProofService: FogMerkleProofService

    init(fogMerkleProofService: FogMerkleProofService, targetQueue: DispatchQueue?) {
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.fogMerkleProofService = fogMerkleProofService
    }

    func getOutputs(
        globalIndicesArray: [[UInt64]],
        merkleRootBlock: UInt64,
        maxNumIndicesPerQuery: Int,
        completion: @escaping (
            Result<FetchResult<[[(TxOut, TxOutMembershipProof)]]>, Error>
        ) -> Void
    ) {
        getOutputs(
            globalIndices: globalIndicesArray.flatMap { $0 },
            merkleRootBlock: merkleRootBlock,
            maxNumIndicesPerQuery: maxNumIndicesPerQuery
        ) {
            completion($0.flatMap { allResults in
                processResults(resultsArray: try globalIndicesArray.map { globalIndices in
                    guard let results = allResults[globalIndices] else {
                        throw ConnectionFailure("\(Self.self).\(#function): " +
                            "global txout indices not found in GetOutputs reponse. " +
                            "globalTxOutIndices: \(globalIndices), " +
                            "returned outputs: \(allResults)")
                    }
                    return results
                })
            })
        }
    }

    func getOutputs(
        globalIndices: [UInt64],
        merkleRootBlock: UInt64,
        maxNumIndicesPerQuery: Int,
        completion: @escaping (
            Result<[UInt64: FetchResult<(TxOut, TxOutMembershipProof)>], Error>
        ) -> Void
    ) {
        let globalIndicesArrays =
            globalIndices.chunked(maxLength: maxNumIndicesPerQuery).map { Array($0) }
        globalIndicesArrays.mapAsync({ chunk, callback in
            getOutputs(globalIndices: chunk, merkleRootBlock: merkleRootBlock, completion: callback)
        }, serialQueue: serialQueue, completion: {
            completion($0.map { arrayOfOutputMaps in
                arrayOfOutputMaps.reduce(into: [:]) { outputMapAccum, outputMap in
                    outputMapAccum.merge(outputMap, uniquingKeysWith: { key1, _ in key1 })
                }
            })
        })
    }

    func getOutputs(
        globalIndices: [UInt64],
        merkleRootBlock: UInt64,
        completion: @escaping (
            Result<[UInt64: FetchResult<(TxOut, TxOutMembershipProof)>], Error>
        ) -> Void
    ) {
        var request = FogLedger_GetOutputsRequest()
        request.indices = globalIndices
        request.merkleRootBlock = merkleRootBlock
        fogMerkleProofService.getOutputs(request: request) {
            completion($0.flatMap {
                try Self.parseResponse(response: $0)
            })
        }
    }

    private static func parseResponse(response: FogLedger_GetOutputsResponse) throws
        -> [UInt64: FetchResult<(TxOut, TxOutMembershipProof)>]
    {
        Dictionary(try response.results.map { outputResult in
            let fetchResult: FetchResult<(TxOut, TxOutMembershipProof)>
            switch outputResult.resultCodeEnum {
            case .exists:
                guard let txOut = TxOut(outputResult.output),
                      let membershipProof = TxOutMembershipProof(outputResult.proof)
                else {
                    throw InternalError("\(Self.self).\(#function): " +
                        "FogMerkleProofService.getOutputs returned invalid result.")
                }
                fetchResult = .success((txOut, membershipProof))
            case .doesNotExist:
                fetchResult = .outOfBounds(
                    blockCount: response.numBlocks,
                    ledgerTxOutCount: response.globalTxoCount)
            case .outputDatabaseError, .intentionallyUnused, .UNRECOGNIZED:
                throw ConnectionFailure("Fog MerkleProof result error: " +
                    "\(outputResult.resultCodeEnum), " +
                    "response: \(response)")
            }

            return (outputResult.index, fetchResult)
        }, uniquingKeysWith: { key1, _ in key1 })
    }
}

extension FogMerkleProofFetcher {
    enum FetchResult<Success> {
        case success(Success)
        case outOfBounds(blockCount: UInt64, ledgerTxOutCount: UInt64)
    }
}

private func processResults(
    resultsArray: [[FogMerkleProofFetcher.FetchResult<(TxOut, TxOutMembershipProof)>]]
) -> FogMerkleProofFetcher.FetchResult<[[(TxOut, TxOutMembershipProof)]]> {
    // Ensure all fetch results are successful, otherwise return outOfBounds
    for result in resultsArray.flatMap({ $0 }) {
        switch result {
        case .success:
            continue
        case let .outOfBounds(blockCount: blockCount, ledgerTxOutCount: txOutCount):
            return .outOfBounds(blockCount: blockCount, ledgerTxOutCount: txOutCount)
        }
    }

    // Convert results to outputs with the assumption that that all results are guaranteed to
    // have succeeded.
    return .success(resultsArray.map { results in
        results.map { result in
            guard case let .success((txOut, membershipProof)) = result else {
                fatalError("Unreachable code")
            }
            return (txOut, membershipProof)
        }
    })
}
