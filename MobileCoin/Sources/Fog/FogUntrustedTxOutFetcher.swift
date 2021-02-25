//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

struct FogUntrustedTxOutFetcher {
    private let serialQueue: DispatchQueue
    private let fogUntrustedTxOutService: FogUntrustedTxOutService

    init(fogUntrustedTxOutService: FogUntrustedTxOutService, targetQueue: DispatchQueue?) {
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.fogUntrustedTxOutService = fogUntrustedTxOutService
    }

    func getOutputs(
        for transaction: Transaction,
        completion: @escaping (Result<(result: FogLedger_TxOutResult, blockCount: UInt64), Error>)
            -> Void
    ) {
        do {
            guard let output = transaction.outputs.first else {
                throw MalformedInput("transaction has no outputs: \(transaction)")
            }

            getTxOut(outputPublicKey: output.publicKey, completion: completion)
        } catch {
            serialQueue.async {
                completion(.failure(error))
            }
        }
    }

    func getTxOut(
        outputPublicKey: RistrettoPublic,
        completion: @escaping (Result<(result: FogLedger_TxOutResult, blockCount: UInt64), Error>)
            -> Void
    ) {
        getTxOuts(outputPublicKeys: [outputPublicKey]) {
            completion($0.flatMap { results, blockCount in
                guard let result =
                        results.first(where: { $0.txOutPubkey.data == outputPublicKey.data })
                else {
                    throw ConnectionFailure("Fog UntrustedTxOut service failed to return the " +
                        "requested TxOut. \(results)")
                }
                return (result, blockCount: blockCount)
            })
        }
    }

    func getTxOuts(
        outputPublicKeys: [RistrettoPublic],
        completion:
            @escaping (Result<(results: [FogLedger_TxOutResult], blockCount: UInt64), Error>)
                -> Void
    ) {
        var request = FogLedger_TxOutRequest()
        request.txOutPubkeys = outputPublicKeys.map { External_CompressedRistretto($0) }
        fogUntrustedTxOutService.getTxOuts(request: request) {
            completion($0.flatMap { response in
                let resultPairs = response.results.map { ($0.txOutPubkey.data, $0) }
                let publicKeyToResult =
                    Dictionary(resultPairs, uniquingKeysWith: { key1, _ in key1 })

                let outputPublicKeys = outputPublicKeys.map { $0.data }
                guard let results = publicKeyToResult[outputPublicKeys] else {
                    throw ConnectionFailure("Fog UntrustedTxOut service failed to return the " +
                        "requested TxOuts. \(response)")
                }

                return (results, blockCount: response.numBlocks)
            })
        }
    }
}
