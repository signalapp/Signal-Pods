//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

public class ServerSecretParams: ByteArray {

  public static func generate() throws  -> ServerSecretParams {
    fatalError("Not implemented.")
  }

  public static func generate(randomness: [UInt8]) throws  -> ServerSecretParams {
    fatalError("Not implemented.")
  }

  public init(contents: [UInt8]) throws {
    fatalError("Not implemented.")
  }

  public func getPublicParams() throws  -> ServerPublicParams {
    fatalError("Not implemented.")
  }

  public func sign(message: [UInt8]) throws  -> NotarySignature {
    fatalError("Not implemented.")
  }

  public func sign(randomness: [UInt8], message: [UInt8]) throws  -> NotarySignature {
    fatalError("Not implemented.")
  }

  public func serialize() -> [UInt8] {
    return contents
  }

}
