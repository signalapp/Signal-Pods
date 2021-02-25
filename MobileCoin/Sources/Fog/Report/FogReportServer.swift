//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable array_init

import Foundation
import LibMobileCoin

final class FogReportServer {
    private let inner: SerialDispatchLock<Inner>

    private let serialConnectionQueue: SerialCallbackQueue

    init(serialExclusionQueue: DispatchQueue) {
        self.inner = .init(Inner(), serialExclusionQueue: serialExclusionQueue)
        self.serialConnectionQueue = .init(targetQueue: serialExclusionQueue)
    }

    func reports(
        reportService: FogReportService,
        completion: @escaping (Result<Report_ReportResponse, Error>) -> Void
    ) {
        fetchReports(reportService: reportService, completion: completion)
    }

    func reports(
        reportService: FogReportService,
        reportParams: [(reportId: String, desiredMinPubkeyExpiry: UInt64)],
        completion: @escaping (Result<Report_ReportResponse, Error>) -> Void
    ) {
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
        completion: @escaping (Result<Report_ReportResponse, Error>) -> Void
    ) {
        serialConnectionQueue.append({ callback in
            self.doFetchReports(reportService: reportService, completion: callback)
        }, completion: completion)
    }

    private func fetchReports(
        reportService: FogReportService,
        reportParams: [(reportId: String, desiredMinPubkeyExpiry: UInt64)],
        completion: @escaping (Result<Report_ReportResponse, Error>) -> Void
    ) {
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
        completion: @escaping (Result<Report_ReportResponse, Error>) -> Void
    ) {
        reportService.getReports(request: Report_ReportRequest()) {
            do {
                let reportResponse = try $0.get()

                // Save report response before releasing the serialConnectionQueue
                // lock. This ensures that, if there's another request waiting, it
                // will have access to the report response we just fetched.
                self.cacheReportResponse(reportResponse) {
                    completion(.success(reportResponse))
                }
            } catch {
                completion(.failure(error))
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
    private class Inner {
        private var cachedReportResponse: Report_ReportResponse?

        func cachedReportResponse(
            satisfyingReportParams reportParams: [(reportId: String, minPubkeyExpiry: UInt64)]
        ) -> Report_ReportResponse? {
            guard let reportResponse = cachedReportResponse,
               reportResponse.isValid(reportParams: reportParams)
            else {
                return nil
            }
            return reportResponse
        }

        func cacheReportResponse(_ reportResponse: Report_ReportResponse) {
            cachedReportResponse = reportResponse
        }
    }
}

extension Report_ReportResponse {
    fileprivate func isValid(reportParams: [(reportId: String, minPubkeyExpiry: UInt64)]) -> Bool {
        reportParams.allSatisfy { reportId, minPubkeyExpiry in
            reports.contains { $0.fogReportID == reportId && $0.pubkeyExpiry >= minPubkeyExpiry }
        }
    }
}
