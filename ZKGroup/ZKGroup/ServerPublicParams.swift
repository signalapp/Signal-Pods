//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ServerPublicParams: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func verifySignature(message: [UInt8], notarySignature: NotarySignature) throws {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }

}
