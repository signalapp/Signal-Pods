//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class GroupPublicParams: ByteArray {

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getGroupIdentifier() throws  -> GroupIdentifier {
    fatalError("Not implemented.")
  }

  public func verifySignature(message: [UInt8], changeSignature: ChangeSignature) throws {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}
