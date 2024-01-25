//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_arguments

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogResolverManager {
    private let serialQueue: DispatchQueue
    private let reportAttestation: Attestation
    private let reportManager: FogReportManager

    init(
        fogReportAttestation: Attestation,
        serviceProvider: ServiceProvider,
        targetQueue: DispatchQueue?
    ) {
        self.serialQueue = DispatchQueue(label: "com.mobilecoin.\(Self.self)", target: targetQueue)
        self.reportAttestation = fogReportAttestation
        self.reportManager =
            FogReportManager(serviceProvider: serviceProvider, targetQueue: targetQueue)
    }

    func fogResolver(
        addresses: [PublicAddress],
        completion: @escaping (Result<FogResolver, ConnectionError>) -> Void
    ) {
        logger.info("addresses: \(addresses.map { "\(redacting: $0)" })")
        let reportUrls = Set(addresses.compactMap { $0.fogReportUrl })
        reportUrls.mapAsync({ reportUrl, callback in
            reportManager.reportResponse(for: reportUrl) {
                callback($0.map { response in
                    (reportUrl, response)
                })
            }
        }, serialQueue: serialQueue, completion: {
            completion($0.map { reportUrlsAndResponses in
                FogResolver(
                    attestation: self.reportAttestation,
                    reportUrlsAndResponses: reportUrlsAndResponses)
            })
        })
    }

    func fogResolver(
        addresses: [PublicAddress],
        desiredMinPubkeyExpiry: UInt64,
        completion: @escaping (Result<FogResolver, ConnectionError>) -> Void
    ) {
        logger.info("\(addresses.map { "\(redacting: $0)" }), " +
            "desiredMinPubkeyExpiry: \(desiredMinPubkeyExpiry)")
        let fogInfos = addresses.compactMap { $0.fogInfo }

        let reportUrlsToFogInfos = Dictionary(grouping: fogInfos, by: { $0.reportUrl })
        let reportUrlsToReportParams = reportUrlsToFogInfos.mapValues { fogInfos in
            fogInfos.map { ($0.reportId, desiredMinPubkeyExpiry) }
        }
        reportUrlsToReportParams.mapAsync({ reportUrlToReportParams, callback in
            let (reportUrl, reportParams) = reportUrlToReportParams
            reportManager.reportResponse(for: reportUrl, reportParams: reportParams) {
                callback($0.map { response in
                    (reportUrl, response)
                })
            }
        }, serialQueue: serialQueue, completion: {
            completion($0.map { reportUrlsAndResponses in
                FogResolver(
                    attestation: self.reportAttestation,
                    reportUrlsAndResponses: reportUrlsAndResponses)
            })
        })
    }
}
