//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ServerZkAuthOperations {

  let serverSecretParams: ServerSecretParams

  public init(serverSecretParams: ServerSecretParams) {
    self.serverSecretParams = serverSecretParams
  }

  public func issueAuthCredential(uuid: ZKGUuid, redemptionTime: UInt32) throws  -> AuthCredentialResponse {
    fatalError("Not implemented.")
  }

  public func issueAuthCredential(randomness: [UInt8], uuid: ZKGUuid, redemptionTime: UInt32) throws  -> AuthCredentialResponse {
    fatalError("Not implemented.")
  }

  public func verifyAuthCredentialPresentation(groupPublicParams: GroupPublicParams, authCredentialPresentation: AuthCredentialPresentation) throws {
    fatalError("Not implemented.")
  }
}
