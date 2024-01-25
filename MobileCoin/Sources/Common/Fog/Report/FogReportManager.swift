//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogReportManager {
    private let inner: SerialDispatchLock<Inner>

    private let serialQueue: DispatchQueue
    private let serviceProvider: ServiceProvider

    init(serviceProvider: ServiceProvider, targetQueue: DispatchQueue?) {
        self.inner = .init(Inner(targetQueue: targetQueue), targetQueue: targetQueue)
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.serviceProvider = serviceProvider
    }

    func reportResponse(
        for reportUrl: FogUrl,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        logger.info("reportUrl: \(reportUrl.url)")
        serviceProvider.fogReportService(for: reportUrl) { reportService in
            self.inner.accessAsync {
                let reportServer = $0.reportServer(for: reportUrl)
                reportServer.reports(reportService: reportService, completion: completion)
            }
        }
    }

    func reportResponse(
        for reportUrl: FogUrl,
        reportParams: [(reportId: String, desiredMinPubkeyExpiry: UInt64)],
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        logger.info("reportUrl: \(reportUrl.url), reportParams: \(reportParams)")
        serviceProvider.fogReportService(for: reportUrl) { reportService in
            self.inner.accessAsync {
                let reportServer = $0.reportServer(for: reportUrl)
                reportServer.reports(
                    reportService: reportService,
                    reportParams: reportParams,
                    completion: completion)
            }
        }
    }
}

extension FogReportManager {
    private struct Inner {
        private let sharedSerialExclusionQueue: DispatchQueue

        private var networkConfigToServer: [FogUrl: FogReportServer] = [:]

        init(targetQueue: DispatchQueue?) {
            self.sharedSerialExclusionQueue = DispatchQueue(
                label: "com.mobilecoin.\(FogReportServer.self)",
                target: targetQueue)
        }

        mutating func reportServer(for reportUrl: FogUrl) -> FogReportServer {
            networkConfigToServer[reportUrl] ?? {
                let reportServer = FogReportServer(serialExclusionQueue: sharedSerialExclusionQueue)
                networkConfigToServer[reportUrl] = reportServer
                return reportServer
            }()
        }
    }
}
