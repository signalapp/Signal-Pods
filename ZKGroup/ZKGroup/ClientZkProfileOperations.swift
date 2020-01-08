//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ClientZkProfileOperations {

  let serverPublicParams: ServerPublicParams

  public init(serverPublicParams: ServerPublicParams) {
    self.serverPublicParams = serverPublicParams
  }

  public func createProfileKeyCredentialRequestContext(uuid: ZKGUuid, profileKey: ProfileKey) throws  -> ProfileKeyCredentialRequestContext {
    fatalError("Not implemented.")
  }

  public func createProfileKeyCredentialRequestContext(randomness: [UInt8], uuid: ZKGUuid, profileKey: ProfileKey) throws  -> ProfileKeyCredentialRequestContext {
    fatalError("Not implemented.")
  }

  public func receiveProfileKeyCredential(profileKeyCredentialRequestContext: ProfileKeyCredentialRequestContext, profileKeyCredentialResponse: ProfileKeyCredentialResponse) throws  -> ProfileKeyCredential {
    fatalError("Not implemented.")
  }

  public func createProfileKeyCredentialPresentation(groupSecretParams: GroupSecretParams, profileKeyCredential: ProfileKeyCredential) throws  -> ProfileKeyCredentialPresentation {
    fatalError("Not implemented.")
  }

  public func createProfileKeyCredentialPresentation(randomness: [UInt8], groupSecretParams: GroupSecretParams, profileKeyCredential: ProfileKeyCredential) throws  -> ProfileKeyCredentialPresentation {
    fatalError("Not implemented.")
  }
}
