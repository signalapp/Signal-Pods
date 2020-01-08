//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ProfileKeyCredentialPresentation: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getUuidCiphertext() throws  -> UuidCiphertext {
    fatalError("Not implemented.")
  }

  public func getProfileKeyCiphertext() throws  -> ProfileKeyCiphertext {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}
