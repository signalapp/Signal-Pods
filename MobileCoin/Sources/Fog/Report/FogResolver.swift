//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class FogResolver {
    private let ptr: OpaquePointer

    convenience init() {
        self.init(attestation: Attestation())
    }

    convenience init(
        attestation: Attestation,
        reportUrlsAndResponses: [(FogUrl, Report_ReportResponse)]
    ) {
        self.init(attestation: attestation)
        for (reportUrl, response) in reportUrlsAndResponses {
            addReportResponse(reportUrl: reportUrl, reportResponse: response)
        }
    }

    private init(attestation: Attestation) {
        let verifier = AttestationVerifier(attestation: attestation)
        // Safety: mc_fog_resolver_create should never return nil.
        self.ptr = verifier.withUnsafeOpaquePointer { verifierPtr in
            withMcInfallible {
                mc_fog_resolver_create(verifierPtr)
            }
        }
    }

    deinit {
        mc_fog_resolver_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }

    private func addReportResponse(reportUrl: FogUrl, reportResponse: Report_ReportResponse) {
        let serializedReportResponse: Data
        do {
            serializedReportResponse = try reportResponse.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError(
                "Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }

        serializedReportResponse.asMcBuffer { reportResponsePtr in
            switch withMcError({ errorPtr in
                mc_fog_resolver_add_report_response(
                    ptr,
                    reportUrl.url.absoluteString,
                    reportResponsePtr,
                    &errorPtr)
            }) {
            case .success:
                break
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: mc_fog_resolver_add_report_response shouldn't fail deserialization
                    // since we just serialized it and roundtrip serialization should always
                    // succeed.
                    logger.fatalError("\(Self.self).\(#function): \(error)")
                default:
                    // Safety: mc_fog_resolver_add_report_response should not throw non-documented
                    // errors.
                    logger.fatalError(
                        "\(Self.self).\(#function): Unhandled LibMobileCoin error: \(error)")
                }
            }
        }
    }
}
