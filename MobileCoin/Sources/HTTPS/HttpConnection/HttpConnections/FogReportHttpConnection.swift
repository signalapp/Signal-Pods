//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif

final class FogReportHttpConnection: ArbitraryHttpConnection, FogReportService {
    private let client: Report_ReportAPIRestClient
    let requester: RestApiRequester

    init(url: FogUrl, requester: RestApiRequester, targetQueue: DispatchQueue?) {
        self.client = Report_ReportAPIRestClient()
        self.requester = requester
        super.init(url: url, targetQueue: targetQueue)
    }

    func getReports(
        request: Report_ReportRequest,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        performCall(
                GetReportsCall(client: client, requester: requester),
                request: request,
                completion: completion)
    }
}

extension FogReportHttpConnection {
    private struct GetReportsCall: HttpCallable {
        let client: Report_ReportAPIRestClient
        let requester: RestApiRequester

        func call(
            request: Report_ReportRequest,
            callOptions: HTTPCallOptions?,
            completion: @escaping (HttpCallResult<Report_ReportResponse>) -> Void
        ) {
            let unaryCall = client.getReports(request, callOptions: callOptions)
            requester.makeRequest(call: unaryCall, completion: completion)
        }
    }
}
