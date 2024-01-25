//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum RootEntropyUtils {
    static func privateKeys(
        fromEntropy entropy: Data
    ) -> (viewPrivateKey: RistrettoPrivate, spendPrivateKey: RistrettoPrivate) {
        var viewPrivateKeyOut = Data32()
        var spendPrivateKeyOut = Data32()
        entropy.asMcBuffer { entropyBufferPtr in
            viewPrivateKeyOut.asMcMutableBuffer { viewPrivateKeyOutPtr in
                spendPrivateKeyOut.asMcMutableBuffer { spendPrivateKeyOutPtr in
                    withMcInfallible {
                        mc_account_private_keys_from_root_entropy(
                            entropyBufferPtr,
                            viewPrivateKeyOutPtr,
                            spendPrivateKeyOutPtr)
                    }
                }
            }
        }

        // Safety: It's safe to skip validation because mc_account_private_keys_from_root_entropy
        // should always return valid RistrettoPrivate values on success.
        return (RistrettoPrivate(skippingValidation: viewPrivateKeyOut),
                RistrettoPrivate(skippingValidation: spendPrivateKeyOut))
    }
}
