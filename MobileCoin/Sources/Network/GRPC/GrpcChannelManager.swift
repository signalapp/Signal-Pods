//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import NIO
import NIOSSL

final class GrpcChannelManager {
    private let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1)
    private var addressToChannel: [GrpcChannelConfig: GRPCChannel] = [:]

    func channel(for config: ConnectionConfigProtocol) -> GRPCChannel {
        channel(for: config.url, trustRoots: config.trustRoots)
    }

    func channel(for url: MobileCoinUrlProtocol, trustRoots: [NIOSSLCertificate]? = nil)
        -> GRPCChannel
    {
        let config = GrpcChannelConfig(url: url, trustRoots: trustRoots)
        guard let channel = addressToChannel[config] else {
            let channel = ClientConnection.create(group: eventLoopGroup, config: config)
            addressToChannel[config] = channel
            return channel
        }
        return channel
    }
}

extension ClientConnection {
    fileprivate static func create(group: EventLoopGroup, config: GrpcChannelConfig) -> GRPCChannel
    {
        let builder: Builder
        if config.useTls {
            let secureBuilder = ClientConnection.secure(group: group)
            if let trustRoots = config.trustRoots {
                secureBuilder.withTLS(trustRoots: .certificates(trustRoots))
            }
            builder = secureBuilder
        } else {
            builder = ClientConnection.insecure(group: group)
        }
        return builder.connect(host: config.host, port: config.port)
    }
}
