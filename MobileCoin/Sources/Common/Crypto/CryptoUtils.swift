//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum CryptoUtils {
    static func ristrettoPrivateValidate(_ bytes: Data) -> Bool {
        bytes.asMcBuffer { bytesPtr in
            var valid = false
            withMcInfallible {
                mc_ristretto_private_validate(bytesPtr, &valid)
            }
            return valid
        }
    }

    static func ristrettoPublicValidate(_ bytes: Data) -> Bool {
        bytes.asMcBuffer { bytesPtr in
            var valid = false
            withMcInfallible {
                mc_ristretto_public_validate(bytesPtr, &valid)
            }
            return valid
        }
    }
}
