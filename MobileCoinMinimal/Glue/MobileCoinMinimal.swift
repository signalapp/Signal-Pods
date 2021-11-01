

import Foundation

public enum MobileCoinMinimalError: Error {
    case invalidReceipt
}

// MARK: -

public class MobileCoinMinimal {
    
    public static func txOutPublicKey(forReceiptData serializedData: Data) throws -> Data {
        guard let proto = try? External_Receipt(serializedData: serializedData) else {
            logger.warning(
                "External_Receipt deserialization failed. serializedData: " +
                "\(redacting: serializedData.base64EncodedString())",
                logFunction: false)
            throw MobileCoinMinimalError.invalidReceipt
        }
        let txOutPublicKey = proto.publicKey.data
        return txOutPublicKey
    }

    public static func isValidMobileCoinPublicAddress(_ serializedData: Data) -> Bool {
        guard let proto = try? External_PublicAddress(serializedData: serializedData) else {
            logger.warning("External_PublicAddress deserialization failed. serializedData: " +
                           "\(redacting: serializedData.base64EncodedString())")
            return false
        }
        return true
    }
}

