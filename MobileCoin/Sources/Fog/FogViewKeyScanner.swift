//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation
import LibMobileCoin

final class FogViewKeyScanner {
    private let accountKey: AccountKey
    private let fogBlockService: FogBlockService

    init(accountKey: AccountKey, fogBlockService: FogBlockService) {
        logger.info("")
        self.accountKey = accountKey
        self.fogBlockService = fogBlockService
    }

    func viewKeyScanBlocks(
        blockRanges: [Range<UInt64>],
        completion: @escaping (Result<[KnownTxOut], ConnectionError>) -> Void
    ) {
        logger.info("")
        fetchBlocksTxOuts(ranges: blockRanges) {
            completion($0.map { blocksTxOuts in
                logger.info(
                    "\(blockRanges.map { $0.count }.reduce(0, +)) missed " +
                        "blocks containing \(blocksTxOuts.count) TxOuts")
                let foundTxOuts = blocksTxOuts.compactMap {
                    KnownTxOut($0, accountKey: self.accountKey)
                }
                logger.info(": Found \(redacting: foundTxOuts.count) missed TxOuts")
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
                            logger.info("failure - Fog Block service returned " +
                                            "invalid output: \(output)")
                            return .failure(.invalidServerResponse(
                                "Fog Block service returned invalid output: \(output)"))
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
