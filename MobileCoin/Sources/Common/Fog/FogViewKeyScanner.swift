//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogViewKeyScanner {
    private let accountKey: AccountKey
    private let fogBlockService: FogBlockService

    init(accountKey: AccountKey, fogBlockService: FogBlockService) {
        self.accountKey = accountKey
        self.fogBlockService = fogBlockService
    }

    func viewKeyScanBlocks(
        blockRanges: [Range<UInt64>],
        completion: @escaping (Result<[KnownTxOut], ConnectionError>) -> Void
    ) {
        logger.info(
            "Fetching block ranges: \(blockRanges.map { "[\($0.lowerBound), \($0.upperBound))" })",
            logFunction: false)

        fetchBlocksTxOuts(ranges: blockRanges) {
            completion($0.map { blocksTxOuts in
                logger.info(
                    "View key scanning blocks: " +
                        "\(blockRanges.map { "[\($0.lowerBound), \($0.upperBound))" }) " +
                        "containing \(blocksTxOuts.count) TxOuts",
                    logFunction: false)

                let foundTxOuts = blocksTxOuts.compactMap {
                    $0.decrypt(accountKey: self.accountKey)
                }
                logger.info(
                    "View key scanning missed blocks found \(redacting: foundTxOuts.count) TxOuts",
                    logFunction: false)
                return foundTxOuts
            })
        }
    }

    func fetchBlocksTxOuts(
        ranges: [Range<UInt64>],
        completion: @escaping (Result<[LedgerTxOut], ConnectionError>) -> Void
    ) {
        var request = FogLedger_BlockRequest()
        request.rangeValues = ranges
        fogBlockService.getBlocks(request: request) {
            completion($0.flatMap { response in
                response.blocks.flatMap { responseBlock -> [Result<LedgerTxOut, ConnectionError>] in
                    let globalIndexStart =
                        responseBlock.globalTxoCount - UInt64(responseBlock.outputs.count)
                    return responseBlock.outputs.enumerated().map { outputIndex, output in
                        guard let partialTxOut = PartialTxOut(output) else {
                            let errorMessage =
                                "Fog Block service returned invalid TxOut: \(output)"
                            logger.error(errorMessage, logFunction: false)
                            return .failure(.invalidServerResponse(errorMessage))
                        }

                        return .success(LedgerTxOut(
                            partialTxOut,
                            globalIndex: globalIndexStart + UInt64(outputIndex),
                            block: responseBlock.metadata))
                    }
                }.collectResult()
            })
        }
    }
}
