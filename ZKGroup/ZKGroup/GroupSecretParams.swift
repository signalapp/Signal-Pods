//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class GroupSecretParams: ByteArray {

  public static func generate() throws  -> GroupSecretParams {
    fatalError("Not implemented.")
  }

  public static func generate(randomness: [UInt8]) throws  -> GroupSecretParams {
    fatalError("Not implemented.")
  }

  public static func deriveFromMasterKey(groupMasterKey: GroupMasterKey) throws  -> GroupSecretParams {
    fatalError("Not implemented.")
  }

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getMasterKey() throws  -> GroupMasterKey {
    fatalError("Not implemented.")
  }

  public func getPublicParams() throws  -> GroupPublicParams {
    fatalError("Not implemented.")
  }

  public func sign(message: [UInt8]) throws  -> ChangeSignature {
    fatalError("Not implemented.")
  }

  public func sign(randomness: [UInt8], message: [UInt8]) throws  -> ChangeSignature {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }
}
