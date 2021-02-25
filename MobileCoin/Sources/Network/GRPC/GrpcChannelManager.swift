//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import NIO

final class GrpcChannelManager {
    private let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1)
    private var addressToChannel: [GrpcChannelConfig: GRPCChannel] = [:]

    func channel(for url: MobileCoinUrlProtocol) -> GRPCChannel {
        let config = GrpcChannelConfig(url: url)
        guard let channel = addressToChannel[config] else {
            let channel = ClientConnection.create(group: eventLoopGroup, config: config)
            addressToChannel[config] = channel
            return channel
        }
        return channel
    }
}

extension ClientConnection {
    fileprivate static func create(group: EventLoopGroup, config: GrpcChannelConfig)
        -> GRPCChannel
    {
        let builder = config.useTls
            ? ClientConnection.secure(group: group)
            : ClientConnection.insecure(group: group)
        return builder.connect(host: config.host, port: config.port)
    }
}
