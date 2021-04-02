// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

extension Printable_PrintableWrapper {
    init?(base58Encoded base58String: String) {
        logger.info("")
        guard case .success(let decodedData) =
            Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                mc_printable_wrapper_b58_decode(base58String, bufferPtr, &errorPtr)
            })
        else {
            return nil
        }

        guard let printableWrapper = try? Self(serializedData: decodedData) else {
            return nil
        }

        self = printableWrapper
    }

    func base58EncodedString() -> String {
        logger.info("")
        let serialized: Data
        do {
            serialized = try serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`.
            logger.fatalError("Protobuf serialization failed: \(redacting: error)")
        }

        return serialized.asMcBuffer { bufferPtr in
            String(mcString: withMcInfallibleReturningOptional {
                mc_printable_wrapper_b58_encode(bufferPtr)
            })
        }
    }
}
