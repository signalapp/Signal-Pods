//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//
//  swiftlint:disable all

import Foundation
import SwiftProtobuf
import LibMobileCoin


//// Blockchain APIRest shared between clients and peers.
///
/// Usage: instantiate `ConsensusCommon_BlockchainAPIRestClient`, then call methods of this protocol to make APIRest calls.
public protocol ConsensusCommon_BlockchainAPIRestClientProtocol: HTTPClient {
  var serviceName: String { get }

  func getLastBlockInfo(
    _ request: SwiftProtobuf.Google_Protobuf_Empty,
    callOptions: HTTPCallOptions?
  ) -> HTTPUnaryCall<SwiftProtobuf.Google_Protobuf_Empty, ConsensusCommon_LastBlockInfoResponse>

  func getBlocks(
    _ request: ConsensusCommon_BlocksRequest,
    callOptions: HTTPCallOptions?
  ) ->HTTPUnaryCall<ConsensusCommon_BlocksRequest, ConsensusCommon_BlocksResponse>
}

extension ConsensusCommon_BlockchainAPIRestClientProtocol {
  public var serviceName: String {
    return "consensus_common.BlockchainAPI"
  }

  /// Unary call to GetLastBlockInfo
  ///
  /// - Parameters:
  ///   - request: Request to send to GetLastBlockInfo.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func getLastBlockInfo(
    _ request: SwiftProtobuf.Google_Protobuf_Empty,
    callOptions: HTTPCallOptions? = nil
  ) ->HTTPUnaryCall<SwiftProtobuf.Google_Protobuf_Empty, ConsensusCommon_LastBlockInfoResponse> {
    return self.makeUnaryCall(
      path: "/consensus_common.BlockchainAPI/GetLastBlockInfo",
      request: request,
      callOptions: callOptions ?? self.defaultHTTPCallOptions
    )
  }

  /// Unary call to GetBlocks
  ///
  /// - Parameters:
  ///   - request: Request to send to GetBlocks.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  public func getBlocks(
    _ request: ConsensusCommon_BlocksRequest,
    callOptions: HTTPCallOptions? = nil
  ) ->HTTPUnaryCall<ConsensusCommon_BlocksRequest, ConsensusCommon_BlocksResponse> {
    return self.makeUnaryCall(
      path: "/consensus_common.BlockchainAPI/GetBlocks",
      request: request,
      callOptions: callOptions ?? self.defaultHTTPCallOptions
    )
  }
}

public final class ConsensusCommon_BlockchainAPIRestClient: ConsensusCommon_BlockchainAPIRestClientProtocol {
  public var defaultHTTPCallOptions: HTTPCallOptions

  /// Creates a client for the consensus_common.BlockchainAPIRest service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultHTTPCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  public init(
    defaultHTTPCallOptions: HTTPCallOptions = HTTPCallOptions()
  ) {
    self.defaultHTTPCallOptions = defaultHTTPCallOptions
  }
}

