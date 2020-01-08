//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ClientZkAuthOperations {

  let serverPublicParams: ServerPublicParams

  public init(serverPublicParams: ServerPublicParams) {
    self.serverPublicParams = serverPublicParams
  }

  public func receiveAuthCredential(uuid: ZKGUuid, redemptionTime: UInt32, authCredentialResponse: AuthCredentialResponse) throws  -> AuthCredential {

    fatalError("Not implemented.")
  }

  public func createAuthCredentialPresentation(groupSecretParams: GroupSecretParams, authCredential: AuthCredential) throws  -> AuthCredentialPresentation {

    fatalError("Not implemented.")
  }

  public func createAuthCredentialPresentation(randomness: [UInt8], groupSecretParams: GroupSecretParams, authCredential: AuthCredential) throws  -> AuthCredentialPresentation {

    fatalError("Not implemented.")
  }
}
