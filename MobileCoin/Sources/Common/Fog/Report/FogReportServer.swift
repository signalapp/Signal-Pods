//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable array_init

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogReportServer {
    private let inner: SerialDispatchLock<Inner>

    private let serialConnectionQueue: SerialCallbackQueue

    init(serialExclusionQueue: DispatchQueue) {
        self.inner = .init(Inner(), serialExclusionQueue: serialExclusionQueue)
        self.serialConnectionQueue = .init(targetQueue: serialExclusionQueue)
    }

    func reports(
        reportService: FogReportService,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        fetchReports(reportService: reportService, completion: completion)
    }

    func reports(
        reportService: FogReportService,
        reportParams: [(reportId: String, desiredMinPubkeyExpiry: UInt64)],
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        logger.info("reportParams: \(reportParams)")
        inner.accessAsync {
            if let reportResponse =
                $0.cachedReportResponse(satisfyingReportParams: reportParams.map { $0 })
            {
                completion(.success(reportResponse))
            } else {
                self.fetchReports(
                    reportService: reportService,
                    reportParams: reportParams,
                    completion: completion)
            }
        }
    }

    private func fetchReports(
        reportService: FogReportService,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        serialConnectionQueue.append({ callback in
            self.doFetchReports(reportService: reportService, completion: callback)
        }, completion: completion)
    }

    private func fetchReports(
        reportService: FogReportService,
        reportParams: [(reportId: String, desiredMinPubkeyExpiry: UInt64)],
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        logger.info("reportParams: \(reportParams)")
        serialConnectionQueue.append({ callback in
            // Now that we have the serialConnectionQueue lock, check again if there's a cached
            // report response that satisfies the reportParams.
            self.inner.accessAsync {
                if let reportResponse =
                    $0.cachedReportResponse(satisfyingReportParams: reportParams.map { $0 })
                {
                    callback(.success(reportResponse))
                } else {
                    // Otherwise, continue with fetching from the network.
                    self.doFetchReports(reportService: reportService, completion: callback)
                }
            }
        }, completion: completion)
    }

    private func doFetchReports(
        reportService: FogReportService,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        reportService.getReports(request: Report_ReportRequest()) {
            guard let reportResponse = $0.successOr(completion: completion) else { return }

            // Save report response before releasing the serialConnectionQueue
            // lock. This ensures that, if there's another request waiting, it
            // will have access to the report response we just fetched.
            self.cacheReportResponse(reportResponse) {
                completion(.success(reportResponse))
            }
        }
    }

    private func cacheReportResponse(
        _ reportResponse: Report_ReportResponse,
        completion: @escaping () -> Void
    ) {
        inner.accessAsync {
            $0.cacheReportResponse(reportResponse)

            completion()
        }
    }
}

extension FogReportServer {
    private struct Inner {
        private var cachedReportResponse: Report_ReportResponse?

        func cachedReportResponse(
            satisfyingReportParams reportParams: [(reportId: String,
                                                   desiredMinPubkeyExpiry: UInt64)]
        ) -> Report_ReportResponse? {
            logger.info("reportParams: \(reportParams)")
            guard let reportResponse = cachedReportResponse else {
                return nil
            }
            guard reportResponse.isValid(reportParams: reportParams) else {
                logger.info("report response invalid - reportParams: \(reportParams)")
                return nil
            }
            logger.info("report response valid - reportParams: \(reportParams)")
            return reportResponse
        }

        mutating func cacheReportResponse(_ reportResponse: Report_ReportResponse) {
            cachedReportResponse = reportResponse
        }
    }
}

extension Report_ReportResponse {
    fileprivate func isValid(reportParams: [(reportId: String,
                                             desiredMinPubkeyExpiry: UInt64)]) -> Bool {
        reportParams.allSatisfy { reportId, desiredMinPubkeyExpiry in
            reports.contains {
                $0.fogReportID == reportId && $0.pubkeyExpiry >= desiredMinPubkeyExpiry
            }
        }
    }
}
