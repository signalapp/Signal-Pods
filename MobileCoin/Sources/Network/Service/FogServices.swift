// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import LibMobileCoin

struct FogViewQueryRequestWrapper {
    var requestAad = FogView_QueryRequestAAD()
    var request = FogView_QueryRequest()
}

protocol FogViewService {
    func query(
        requestAad: FogView_QueryRequestAAD,
        request: FogView_QueryRequest,
        completion: @escaping (Result<FogView_QueryResponse, ConnectionError>) -> Void)
}

extension FogViewService {
    func query(
        requestWrapper wrapper: FogViewQueryRequestWrapper,
        completion: @escaping (Result<FogView_QueryResponse, ConnectionError>) -> Void
    ) {
        query(requestAad: wrapper.requestAad, request: wrapper.request, completion: completion)
    }
}

protocol FogMerkleProofService {
    func getOutputs(
        request: FogLedger_GetOutputsRequest,
        completion: @escaping (Result<FogLedger_GetOutputsResponse, ConnectionError>) -> Void)
}

protocol FogKeyImageService {
    func checkKeyImages(
        request: FogLedger_CheckKeyImagesRequest,
        completion: @escaping (Result<FogLedger_CheckKeyImagesResponse, ConnectionError>) -> Void)
}

protocol FogBlockService {
    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, ConnectionError>) -> Void)
}

protocol FogUntrustedTxOutService {
    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, ConnectionError>) -> Void)
}

protocol FogReportService {
    func getReports(
        request: Report_ReportRequest,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void)
}
