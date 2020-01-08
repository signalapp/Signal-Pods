//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

public class ZKGUuid: ByteArray {

  static let SIZE: Int = 16

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}
