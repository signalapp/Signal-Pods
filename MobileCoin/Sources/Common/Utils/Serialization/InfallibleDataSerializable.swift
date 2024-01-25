//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import SwiftProtobuf

protocol InfallibleDataSerializable {
    var serializedDataInfallible: Data { get }
}

extension InfallibleDataSerializable where Self: Message {
    var serializedDataInfallible: Data {
        do {
            return try serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError("Protobuf serialization failed: \(redacting: error)")
        }
    }
}
