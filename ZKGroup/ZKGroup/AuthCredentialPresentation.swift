//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class AuthCredentialPresentation: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getUuidCiphertext() throws  -> UuidCiphertext {
    fatalError("Not implemented.")
  }

  public func getRedemptionTime() throws  -> UInt32 {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }

}
