// swiftlint:disable:this file_name

//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_parameters_brackets

import Foundation
import LibMobileCoin

protocol FogViewService {
    func query(
        requestAad: FogView_QueryRequestAAD,
        request: FogView_QueryRequest,
        completion: @escaping (Result<FogView_QueryResponse, Error>) -> Void)
}

protocol FogMerkleProofService {
    func getOutputs(
        request: FogLedger_GetOutputsRequest,
        completion: @escaping (Result<FogLedger_GetOutputsResponse, Error>) -> Void)
}

protocol FogKeyImageService {
    func checkKeyImages(
        request: FogLedger_CheckKeyImagesRequest,
        completion: @escaping (Result<FogLedger_CheckKeyImagesResponse, Error>) -> Void)
}

protocol FogBlockService {
    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, Error>) -> Void)
}

protocol FogUntrustedTxOutService {
    func getTxOuts(
        request: FogLedger_TxOutRequest,
        completion: @escaping (Result<FogLedger_TxOutResponse, Error>) -> Void)
}

protocol FogReportService {
    func getReports(
        request: Report_ReportRequest,
        completion: @escaping (Result<Report_ReportResponse, Error>) -> Void)
}
