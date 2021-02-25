// swiftlint:disable:this file_name

//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import LibMobileCoin

/// This file contains temporary interop code to allow easy source compatibility with upstream
/// LibMobileCoin and MobileCoin server code. The code in this file can be removed once upstream
/// is deployed to alpha and the older server code no longer needs to be supported.

extension External_AccountKey {
    var fogAuthoritySpki: Data {
        get { fogAuthorityFingerprint }
        set { fogAuthorityFingerprint = newValue }
    }
}

extension External_PublicAddress {
    var fogAuthoritySig: Data {
        get { fogAuthorityFingerprintSig }
        set { fogAuthorityFingerprintSig = newValue }
    }
}

func mc_account_key_get_public_address_fog_authority_sig(
    _ account_key: UnsafePointer<McAccountKey>,
    _ subaddress_index: UInt64,
    _ out_fog_authority_sig: UnsafeMutablePointer<McMutableBuffer>
) -> Bool {
    mc_account_key_get_public_address_fog_authority_fingerprint_sig(
        account_key,
        subaddress_index,
        out_fog_authority_sig)
}
