// swiftlint:disable:this file_name

//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

extension Printable_PrintableWrapper {
    init?(base58Encoded base58String: String) {
        guard case .success(let decodedData) =
            Data.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                mc_printable_wrapper_b58_decode(base58String, bufferPtr, &errorPtr)
            })
        else {
            logger.warning("PrintableWrapper base-58 decoding failed.")
            return nil
        }

        guard let printableWrapper = try? Self(serializedData: decodedData) else {
            logger.warning("Printable_PrintableWrapper deserialization failed.")
            return nil
        }

        self = printableWrapper
    }

    func base58EncodedString() -> String {
        let serialized = serializedDataInfallible
        return serialized.asMcBuffer { bufferPtr in
            String(mcString: withMcInfallibleReturningOptional {
                mc_printable_wrapper_b58_encode(bufferPtr)
            })
        }
    }
}
