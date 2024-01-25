//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

struct FogUntrustedTxOutFetcher {
    private let fogUntrustedTxOutService: FogUntrustedTxOutService

    init(fogUntrustedTxOutService: FogUntrustedTxOutService) {
        self.fogUntrustedTxOutService = fogUntrustedTxOutService
    }

    func getTxOut(
        outputPublicKey: RistrettoPublic,
        completion: @escaping (
            Result<(result: FogLedger_TxOutResult, blockCount: UInt64), ConnectionError>
        ) -> Void
    ) {
        getTxOuts(outputPublicKeys: [outputPublicKey]) {
            completion($0.flatMap { results, blockCount in
                guard let result =
                        results.first(where: { $0.txOutPubkey.data == outputPublicKey.data })
                else {
                    logger.info("failure - Fog UntrustedTxOut service failed to " +
                        "return the requested TxOut: \(redacting: results)")
                    return .failure(.invalidServerResponse(
                        "Fog UntrustedTxOut service failed to return the requested TxOut. " +
                        "\(results)"))
                }
                return .success((result, blockCount: blockCount))
            })
        }
    }

    func getTxOuts(
        outputPublicKeys: [RistrettoPublic],
        completion:
            @escaping (
                Result<(results: [FogLedger_TxOutResult], blockCount: UInt64), ConnectionError>
            ) -> Void
    ) {
        logger.info(
            "outputPublicKeys: \(redacting: outputPublicKeys.map { $0.hexEncodedString() })")
        var request = FogLedger_TxOutRequest()
        request.txOutPubkeys = outputPublicKeys.map { External_CompressedRistretto($0) }
        fogUntrustedTxOutService.getTxOuts(request: request) {
            completion($0.flatMap { response in
                let resultPairs = response.results.map { ($0.txOutPubkey.data, $0) }
                let publicKeyToResult =
                    Dictionary(resultPairs, uniquingKeysWith: { key1, _ in key1 })

                let outputPublicKeys = outputPublicKeys.map { $0.data }
                guard let results = publicKeyToResult[outputPublicKeys] else {
                    logger.info("failure - Fog UntrustedTxOut service failed to " +
                        "return the requested TxOuts: \(redacting: response.results)")
                    return .failure(.invalidServerResponse(
                        "Fog UntrustedTxOut service failed to return the requested TxOuts. " +
                        "\(response)"))
                }

                return .success((results, blockCount: response.numBlocks))
            })
        }
    }
}
