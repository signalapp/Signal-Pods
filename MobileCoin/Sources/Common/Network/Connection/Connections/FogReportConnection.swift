//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

final class FogReportConnection: ArbitraryConnection<
        GrpcProtocolConnectionFactory.FogReportServiceProvider,
        HttpProtocolConnectionFactory.FogReportServiceProvider
    >,
    FogReportService
{
    private let httpFactory: HttpProtocolConnectionFactory
    private let grpcFactory: GrpcProtocolConnectionFactory
    private let url: FogUrl
    private let targetQueue: DispatchQueue?

    init(
        httpFactory: HttpProtocolConnectionFactory,
        grpcFactory: GrpcProtocolConnectionFactory,
        url: FogUrl,
        transportProtocolOption: TransportProtocol.Option,
        targetQueue: DispatchQueue?
    ) {
        self.httpFactory = httpFactory
        self.grpcFactory = grpcFactory
        self.url = url
        self.targetQueue = targetQueue

        super.init(
            connectionOptionWrapperFactory: { transportProtocolOption in
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService:
                            grpcFactory.makeFogReportService(
                                url: url,
                                transportProtocolOption: transportProtocolOption,
                                targetQueue: targetQueue))
                case .http:
                    return .http(httpService:
                            httpFactory.makeFogReportService(
                                url: url,
                                transportProtocolOption: transportProtocolOption,
                                targetQueue: targetQueue))
                }
            },
            transportProtocolOption: transportProtocolOption,
            targetQueue: targetQueue)
    }

    func getReports(
        request: Report_ReportRequest,
        completion: @escaping (Result<Report_ReportResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.getReports(request: request, completion: completion)
        case .http(let httpConnection):
            httpConnection.getReports(request: request, completion: completion)
        }
    }
}
