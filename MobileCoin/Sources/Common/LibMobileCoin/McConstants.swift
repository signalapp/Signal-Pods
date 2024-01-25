//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

enum McConstants {}

// MARK: - Transaction

extension McConstants {

    /// Each input ring must contain this many elements.
    static let RING_SIZE = 11

    /// Each transaction must contain no more than this many inputs (rings).
    static let MAX_INPUTS = 16

    /// Each transaction must contain no more than this many outputs.
    static let MAX_OUTPUTS = 16

    /// Maximum number of blocks in the future a transaction's tombstone block can be set to.
    static let MAX_TOMBSTONE_BLOCKS: UInt64 = 100

    /// Minimum allowed fee, denominated in picoMOB.
    static let DEFAULT_MINIMUM_FEE: UInt64 = 400_000_000

    /// Transaction hash length, in bytes.
    static let TX_HASH_LEN = 32

    /// Length of a Transaction's encrypted fog hint field, in bytes.
    static let ENCRYPTED_FOG_HINT_LEN = 128

    /// Length of a Transaction confirmation number, in bytes.
    static let CONFIRMATION_NUMBER_LEN = 32

}

// MARK: - Block

extension McConstants {

    /// Maximum number of transactions that may be included in a Block.
    static let MAX_TRANSACTIONS_PER_BLOCK = 5000

}

// MARK: - TxOut

extension McConstants {

    /// Length of a TxOut key image, in bytes.
    static let KEY_IMAGE_LEN = 32

}

// MARK: - MOB

extension McConstants {

    /// The MobileCoin network will contain a fixed supply of 250 million mobilecoins (MOB).
    static let TOTAL_MOB: UInt64 = 250_000_000

}

// MARK: - Account key

extension McConstants {

    /// Length of the root entropy used to construct an account key, in bytes.
    static let ROOT_ENTROPY_LEN = 32

    /// An account's "default address" is its zero^th subaddress.
    static let DEFAULT_SUBADDRESS_INDEX: UInt64 = 0

    /// An account's "default change address" is its first subaddress.
    static let DEFAULT_CHANGE_SUBADDRESS_INDEX = UInt64.max - 1

    /// Possible subaddresses that a TxOut can be owned by
    static let POSSIBLE_SUBADDRESSES: [UInt64] = [
        Self.DEFAULT_CHANGE_SUBADDRESS_INDEX,
        Self.DEFAULT_SUBADDRESS_INDEX,
    ]
}

// MARK: - Keys

extension McConstants {

    /// Ristretto private key length, in bytes.
    static let RISTRETTO_PRIVATE_LEN = 32

    /// Ristretto public key length, in bytes.
    static let RISTRETTO_PUBLIC_LEN = 32

    /// The length of a curve25519 EdDSA `Signature`, in bytes.
    static let SCHNORRKEL_SIGNATURE_LEN = 64

}

// MARK: - Attestation

extension McConstants {

    /// MRENCLAVE length, in bytes.
    static let MRENCLAVE_LEN = 32

    /// MRSIGNER length, in bytes.
    static let MRSIGNER_LEN = 32

}

// MARK: - Enclave

extension McConstants {

    static let CONSENSUS_PRODUCT_ID: UInt16 = 1
    static let FOG_VIEW_PRODUCT_ID: UInt16 = 3
    static let FOG_LEDGER_PRODUCT_ID: UInt16 = 2
    static let FOG_REPORT_PRODUCT_ID: UInt16 = 4
    static let MISTYSWAP_PRODUCT_ID: UInt16 = 2

    static let CONSENSUS_SECURITY_VERSION: UInt16 = 1
    static let DEV_CONSENSUS_MRSIGNER_HEX =
        "7ee5e29d74623fdbc6fbf1454be6f3bb0b86c12366b7b478ad13353e44de8411"
    static let DEV_CONSENSUS_MRSIGNER = Data([
        126, 229, 226, 157, 116, 98, 63, 219, 198, 251, 241, 69, 75, 230, 243, 187, 11, 134, 193,
        35, 102, 183, 180, 120, 173, 19, 53, 62, 68, 222, 132, 17,
    ])
    static let TESTNET_CONSENSUS_MRSIGNER_HEX =
        "bf7fa957a6a94acb588851bc8767e0ca57706c79f4fc2aa6bcb993012c3c386c"
    static let TESTNET_CONSENSUS_MRSIGNER = Data([
        191, 127, 169, 87, 166, 169, 74, 203, 88, 136, 81, 188, 135, 103, 224, 202, 87, 112, 108,
        121, 244, 252, 42, 166, 188, 185, 147, 1, 44, 60, 56, 108,
    ])

    static let FOG_VIEW_SECURITY_VERSION: UInt16 = 1
    static let FOG_LEDGER_SECURITY_VERSION: UInt16 = 1
    static let DEV_FOG_MRSIGNER_HEX =
        "7ee5e29d74623fdbc6fbf1454be6f3bb0b86c12366b7b478ad13353e44de8411"
    static let DEV_FOG_MRSIGNER = Data([
        126, 229, 226, 157, 116, 98, 63, 219, 198, 251, 241, 69, 75, 230, 243, 187, 11, 134, 193,
        35, 102, 183, 180, 120, 173, 19, 53, 62, 68, 222, 132, 17,
    ])
    static let TESTNET_FOG_MRSIGNER_HEX =
        "bf7fa957a6a94acb588851bc8767e0ca57706c79f4fc2aa6bcb993012c3c386c"
    static let TESTNET_FOG_MRSIGNER = Data([
        191, 127, 169, 87, 166, 169, 74, 203, 88, 136, 81, 188, 135, 103, 224, 202, 87, 112, 108,
        121, 244, 252, 42, 166, 188, 185, 147, 1, 44, 60, 56, 108,
    ])

    static let FOG_REPORT_SECURITY_VERSION: UInt16 = 1
    static let DEV_FOG_REPORT_MRSIGNER_HEX =
        "7ee5e29d74623fdbc6fbf1454be6f3bb0b86c12366b7b478ad13353e44de8411"
    static let DEV_FOG_REPORT_MRSIGNER = Data([
        126, 229, 226, 157, 116, 98, 63, 219, 198, 251, 241, 69, 75, 230, 243, 187, 11, 134, 193,
        35, 102, 183, 180, 120, 173, 19, 53, 62, 68, 222, 132, 17,
    ])
    static let TESTNET_FOG_REPORT_MRSIGNER_HEX =
        "bf7fa957a6a94acb588851bc8767e0ca57706c79f4fc2aa6bcb993012c3c386c"
    static let TESTNET_FOG_REPORT_MRSIGNER = Data([
        191, 127, 169, 87, 166, 169, 74, 203, 88, 136, 81, 188, 135, 103, 224, 202, 87, 112, 108,
        121, 244, 252, 42, 166, 188, 185, 147, 1, 44, 60, 56, 108,
    ])

    static let MISTYSWAP_SECURITY_VERSION: UInt16 = 6
}

// MARK: - Url

extension McConstants {

    static let MOB_URI_SCHEME = "mob"

    /// The part before the '://' of a URL.
    static let CONSENSUS_SCHEME_SECURE = "mc"
    static let CONSENSUS_SCHEME_INSECURE = "insecure-mc"

    /// Default port numbers
    static let CONSENSUS_DEFAULT_SECURE_PORT = 443
    static let CONSENSUS_DEFAULT_INSECURE_PORT = 3223

    /// The part before the '://' of a URL.
    static let MISTYSWAP_SCHEME_SECURE = "mistyswap"
    static let MISTYSWAP_SCHEME_INSECURE = "insecure-mistyswap"

    /// Default port numbers
    static let MISTYSWAP_DEFAULT_SECURE_PORT = 443
    static let MISTYSWAP_DEFAULT_INSECURE_PORT = 3223

    /// The part before the '://' of a URL.
    static let FOG_SCHEME_SECURE = "fog"
    static let FOG_SCHEME_INSECURE = "insecure-fog"

    /// Default port numbers
    static let FOG_DEFAULT_SECURE_PORT = 443
    static let FOG_DEFAULT_INSECURE_PORT = 3225

}

// MARK: - Fog Report

extension McConstants {

    /// Fog authority subjectPublicKeyInfo used in development, in hexidecimal.
    static let DEV_FOG_AUTHORITY_SPKI_HEX = "23e9dfabdaf74c69428ec0dfac15784eedc7466e"
    /// Fog authority subjectPublicKeyInfo used in development, in bytes.
    static let DEV_FOG_AUTHORITY_SPKI = Data([
        35, 233, 223, 171, 218, 247, 76, 105, 66, 142, 192, 223, 172, 21, 120, 78, 237, 199, 70,
        110,
    ])

}

// MARK: - Fog Ledger

extension McConstants {

    /// Maximum number of Key Images that may be checked in a single request.
    static let FOG_KEY_IMAGE_MAX_REQUEST_SIZE = 2000

}

// MARK: - TxOut

extension McConstants {

    /// Maximum number of Key Images that may be checked in a single request.
    static let LEGACY_MOB_MASKED_TOKEN_ID = Data()

}
