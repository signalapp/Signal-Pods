//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ClientZkGroupCipher {

  let groupSecretParams: GroupSecretParams

  public init(groupSecretParams: GroupSecretParams) {
    self.groupSecretParams = groupSecretParams
  }

  public func encryptUuid(uuid: ZKGUuid) throws  -> UuidCiphertext {
    fatalError("Not implemented.")
  }

  public func decryptUuid(uuidCiphertext: UuidCiphertext) throws  -> ZKGUuid {
    fatalError("Not implemented.")
  }

  public func encryptProfileKey(profileKey: ProfileKey) throws  -> ProfileKeyCiphertext {
    fatalError("Not implemented.")
  }

  public func encryptProfileKey(randomness: [UInt8], profileKey: ProfileKey) throws  -> ProfileKeyCiphertext {
    fatalError("Not implemented.")
  }

  public func decryptProfileKey(profileKeyCiphertext: ProfileKeyCiphertext) throws  -> ProfileKey {
    fatalError("Not implemented.")
  }

  public func encryptBlob(plaintext: [UInt8]) throws  -> [UInt8] {
    fatalError("Not implemented.")
  }

  public func decryptBlob(blobCiphertext: [UInt8]) throws  -> [UInt8] {
    fatalError("Not implemented.")
  }

}
