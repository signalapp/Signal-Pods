//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

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
        for reportUrl: FogReportUrl,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        let reportService = serviceProvider.fogReportService(for: reportUrl)

        self.inner.accessAsync {
            let reportServer = $0.reportServer(for: reportUrl)
            reportServer.reports(reportService: reportService, completion: completion)
        }
    }

    func reportResponse(
        for reportUrl: FogReportUrl,
        reportParams: [(reportId: String, desiredMinPubkeyExpiry: UInt64)],
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        let reportService = serviceProvider.fogReportService(for: reportUrl)

        self.inner.accessAsync {
            let reportServer = $0.reportServer(for: reportUrl)
            reportServer.reports(
                reportService: reportService,
                reportParams: reportParams,
                completion: completion)
        }
    }
}

extension FogReportManager {
    private class Inner {
        private let sharedSerialExclusionQueue: DispatchQueue

        private var networkConfigToServer: [GrpcChannelConfig: FogReportServer] = [:]

        init(targetQueue: DispatchQueue?) {
            self.sharedSerialExclusionQueue = DispatchQueue(
                label: "com.mobilecoin.\(FogReportServer.self)",
                target: targetQueue)
        }

        func reportServer(for reportUrl: FogReportUrl) -> FogReportServer {
            let config = GrpcChannelConfig(url: reportUrl)
            return networkConfigToServer[config] ?? {
                let reportServer = FogReportServer(serialExclusionQueue: sharedSerialExclusionQueue)
                networkConfigToServer[config] = reportServer
                return reportServer
            }()
        }
    }
}
