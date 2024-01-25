//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_arguments multiline_function_chains
// swiftlint:disable closure_body_length

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum FogMerkleProofFetcherError: Error {
    case connectionError(ConnectionError)
    case outOfBounds(blockCount: UInt64, ledgerTxOutCount: UInt64)
}

extension FogMerkleProofFetcherError: CustomStringConvertible {
    var description: String {
        "Fog Merkle Proof Fetcher error: " + {
            switch self {
            case .connectionError(let innerError):
                return "\(innerError)"
            case let .outOfBounds(blockCount: blockCount, ledgerTxOutCount: txOutCount):
                return "Out of bounds: blockCount: \(blockCount), globalTxOutCount: \(txOutCount)"
            }
        }()
    }
}

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
            Result<[[(TxOut, TxOutMembershipProof)]], FogMerkleProofFetcherError>
        ) -> Void
    ) {
        getOutputs(
            globalIndices: globalIndicesArray.flatMap { $0 },
            merkleRootBlock: merkleRootBlock,
            maxNumIndicesPerQuery: maxNumIndicesPerQuery
        ) {
            completion($0.flatMap { allResults in
                globalIndicesArray.map { globalIndices in
                    guard let results = allResults[globalIndices] else {
                        return .failure(.connectionError(.invalidServerResponse(
                            "Global txout indices not found in GetOutputs reponse. " +
                            "globalTxOutIndices: \(globalIndices), returned outputs: " +
                            "\(allResults)")))
                    }
                    return .success(results)
                }.collectResult()
            })
        }
    }

    func getOutputs(
        globalIndices: [UInt64],
        merkleRootBlock: UInt64,
        maxNumIndicesPerQuery: Int,
        completion: @escaping (
            Result<[UInt64: (TxOut, TxOutMembershipProof)], FogMerkleProofFetcherError>
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
            Result<[UInt64: (TxOut, TxOutMembershipProof)], FogMerkleProofFetcherError>
        ) -> Void
    ) {
        var request = FogLedger_GetOutputsRequest()
        request.indices = globalIndices
        request.merkleRootBlock = merkleRootBlock
        fogMerkleProofService.getOutputs(request: request) {
            completion(
                $0.mapError { .connectionError($0) }
                    .flatMap { Self.parseResponse(response: $0) })
        }
    }

    private static func parseResponse(response: FogLedger_GetOutputsResponse)
        -> Result<[UInt64: (TxOut, TxOutMembershipProof)], FogMerkleProofFetcherError>
    {
        response.results.map { outputResult in
            switch outputResult.resultCodeEnum {
            case .exists:
                break
            case .doesNotExist:
                return .failure(.outOfBounds(
                    blockCount: response.numBlocks,
                    ledgerTxOutCount: response.globalTxoCount))
            case .outputDatabaseError, .intentionallyUnused, .UNRECOGNIZED:
                return .failure(.connectionError(.invalidServerResponse(
                    "FogMerkleProofService.getOutputs result code error: " +
                        "\(outputResult.resultCodeEnum), response: \(redacting: response)")))
            }

            let txOut: TxOut
            switch TxOut.make(outputResult.output) {
            case .success(let result):
                txOut = result
            case .failure(let error):
                return .failure(.connectionError(.invalidServerResponse(
                    "FogMerkleProofService.getOutputs returned invalid TxOut. error: \(error)")))
            }

            let membershipProof: TxOutMembershipProof
            switch TxOutMembershipProof.make(outputResult.proof) {
            case .success(let result):
                membershipProof = result
            case .failure(let error):
                return .failure(.connectionError(.invalidServerResponse(
                    "FogMerkleProofService.getOutputs returned invalid membership proof. error: " +
                        "\(error)")))
            }

            return .success((outputResult.index, (txOut, membershipProof)))
        }.collectResult().map {
            Dictionary($0, uniquingKeysWith: { key1, _ in key1 })
        }
    }
}
