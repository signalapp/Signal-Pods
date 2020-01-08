//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ServerZkProfileOperations {

  let serverSecretParams: ServerSecretParams

  public init(serverSecretParams: ServerSecretParams) {
    self.serverSecretParams = serverSecretParams
  }

  public func issueProfileKeyCredential(profileKeyCredentialRequest: ProfileKeyCredentialRequest, uuid: ZKGUuid, profileKeyCommitment: ProfileKeyCommitment) throws  -> ProfileKeyCredentialResponse {
    fatalError("Not implemented.")
  }

  public func issueProfileKeyCredential(randomness: [UInt8], profileKeyCredentialRequest: ProfileKeyCredentialRequest, uuid: ZKGUuid, profileKeyCommitment: ProfileKeyCommitment) throws  -> ProfileKeyCredentialResponse {
    fatalError("Not implemented.")
  }

  public func verifyProfileKeyCredentialPresentation(groupPublicParams: GroupPublicParams, profileKeyCredentialPresentation: ProfileKeyCredentialPresentation) throws {
    fatalError("Not implemented.")
  }

}
