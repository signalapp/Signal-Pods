//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable function_parameter_count

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

enum AccountKeyUtils {
    static func subaddressPrivateKeys(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        subaddressIndex: UInt64
    ) -> (viewKey: RistrettoPrivate, spendKey: RistrettoPrivate) {
        var subaddressViewPrivateKeyOut = Data32()
        var subaddressSpendPrivateKeyOut = Data32()
        viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
            spendPrivateKey.asMcBuffer { spendKeyBufferPtr in
                subaddressViewPrivateKeyOut.asMcMutableBuffer { viewPrivateKeyOutPtr in
                    subaddressSpendPrivateKeyOut.asMcMutableBuffer { spendPrivateKeyOutPtr in
                        withMcInfallible {
                            mc_account_key_get_subaddress_private_keys(
                                viewKeyBufferPtr,
                                spendKeyBufferPtr,
                                subaddressIndex,
                                viewPrivateKeyOutPtr,
                                spendPrivateKeyOutPtr)
                        }
                    }
                }
            }
        }
        // Safety: It's safe to skip validation because mc_account_key_get_subaddress_private_keys
        // should always return valid RistrettoPrivate values on success.
        return (RistrettoPrivate(skippingValidation: subaddressViewPrivateKeyOut),
                RistrettoPrivate(skippingValidation: subaddressSpendPrivateKeyOut))
    }

    static func publicAddressPublicKeys(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        subaddressIndex: UInt64
    ) -> (viewPublicKey: RistrettoPublic, spendPublicKey: RistrettoPublic) {
        var viewPublicKeyOut = Data32()
        var spendPublicKeyOut = Data32()
        viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
            spendPrivateKey.asMcBuffer { spendKeyBufferPtr in
                viewPublicKeyOut.asMcMutableBuffer { viewPublicKeyOutPtr in
                    spendPublicKeyOut.asMcMutableBuffer { spendPublicKeyOutPtr in
                        withMcInfallible {
                            mc_account_key_get_public_address_public_keys(
                                viewKeyBufferPtr,
                                spendKeyBufferPtr,
                                subaddressIndex,
                                viewPublicKeyOutPtr,
                                spendPublicKeyOutPtr)
                        }
                    }
                }
            }
        }
        // Safety: It's safe to skip validation because
        // mc_account_key_get_public_address_public_keys should always return valid RistrettoPublic
        // values on success.
        return (RistrettoPublic(skippingValidation: viewPublicKeyOut),
                RistrettoPublic(skippingValidation: spendPublicKeyOut))
    }

    static func fogAuthoritySig(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        reportUrl: String,
        reportId: String,
        authoritySpki: Data,
        subaddressIndex: UInt64
    ) -> Data {
        McAccountKey.withUnsafePointer(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            reportUrl: reportUrl,
            reportId: reportId,
            authoritySpki: authoritySpki
        ) { accountKeyPtr in
            Data(withFixedLengthMcMutableBufferInfallible: McConstants.SCHNORRKEL_SIGNATURE_LEN)
            { bufferPtr in
                mc_account_key_get_public_address_fog_authority_sig(
                    accountKeyPtr,
                    subaddressIndex,
                    bufferPtr)
            }
        }
    }

    static func publicAddressShortHash(
        publicAddress: PublicAddress
    ) -> AddressHash? {
        publicAddress.withUnsafeCStructPointer { publicAddressPtr in
            switch Data16.make(withMcMutableBuffer: { bufferPtr, errorPtr in
                mc_account_key_get_short_address_hash(
                    publicAddressPtr,
                    bufferPtr,
                    &errorPtr)
            }) {
            case .success(let bytes):
                return AddressHash(bytes)
            case .failure(let error):
                switch error.errorCode {
                case .invalidInput:
                    // Safety: This condition indicates a programming error and can only
                    // happen if arguments mc_account_key_get_short_address_hash are
                    // supplied incorrectly.
                    logger.warning("error: \(redacting: error)")
                    return nil
                default:
                    // Safety: mc_account_key_get_short_address_hash should not throw
                    // non-documented errors.
                    logger.fatalError("Unhandled LibMobileCoin error: \(redacting: error)")
                }
            }
        }
    }
}

extension McAccountKey {
    static func withUnsafePointer<T>(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        fogInfo: AccountKey.FogInfo?,
        body: (UnsafePointer<McAccountKey>) throws -> T
    ) rethrows -> T {
        guard let fogInfo = fogInfo else {
            return try McAccountKey.withUnsafePointer(
                viewPrivateKey: viewPrivateKey,
                spendPrivateKey: spendPrivateKey,
                body: body)
        }
        return try McAccountKey.withUnsafePointer(
            viewPrivateKey: viewPrivateKey,
            spendPrivateKey: spendPrivateKey,
            reportUrl: fogInfo.reportUrlString,
            reportId: fogInfo.reportId,
            authoritySpki: fogInfo.authoritySpki,
            body: body)
    }

    static func withUnsafePointer<T>(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        reportUrl: String,
        reportId: String,
        authoritySpki: Data,
        body: (UnsafePointer<McAccountKey>) throws -> T
    ) rethrows -> T {
        try McAccountKeyFogInfo.withUnsafePointer(
            reportUrl: reportUrl,
            reportId: reportId,
            authoritySpki: authoritySpki
        ) { fogInfoPtr in
            try viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                try spendPrivateKey.asMcBuffer { spendKeyBufferPtr in
                    var publicAddress = McAccountKey(
                        view_private_key: viewKeyBufferPtr,
                        spend_private_key: spendKeyBufferPtr,
                        fog_info: fogInfoPtr)
                    return try body(&publicAddress)
                }
            }
        }
    }

    fileprivate static func withUnsafePointer<T>(
        viewPrivateKey: RistrettoPrivate,
        spendPrivateKey: RistrettoPrivate,
        body: (UnsafePointer<McAccountKey>) throws -> T
    ) rethrows -> T {
        try viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
            try spendPrivateKey.asMcBuffer { spendKeyBufferPtr in
                var publicAddress = McAccountKey(
                    view_private_key: viewKeyBufferPtr,
                    spend_private_key: spendKeyBufferPtr,
                    fog_info: nil)
                return try body(&publicAddress)
            }
        }
    }
}

extension AccountKey: CStructWrapper {
    typealias CStruct = McAccountKey

    func withUnsafeCStructPointer<R>(
        _ body: (UnsafePointer<McAccountKey>) throws -> R
    ) rethrows -> R {
        try fogInfo.withUnsafeCStructPointer { fogInfoPtr in
            try viewPrivateKey.asMcBuffer { viewKeyBufferPtr in
                try spendPrivateKey.asMcBuffer { spendKeyBufferPtr in
                    var publicAddress = McAccountKey(
                        view_private_key: viewKeyBufferPtr,
                        spend_private_key: spendKeyBufferPtr,
                        fog_info: fogInfoPtr)
                    return try body(&publicAddress)
                }
            }
        }
    }
}

extension McAccountKeyFogInfo {
    fileprivate static func withUnsafePointer<T>(
        reportUrl: String,
        reportId: String,
        authoritySpki: Data,
        body: (UnsafePointer<McAccountKeyFogInfo>) throws -> T
    ) rethrows -> T {
        try reportUrl.withCString { reportUrlPtr in
            try reportId.withCString { reportIdPtr in
                try authoritySpki.asMcBuffer { authoritySpkiPtr in
                    var mcFogInfo = McAccountKeyFogInfo(
                        report_url: reportUrlPtr,
                        report_id: reportIdPtr,
                        authority_fingerprint: authoritySpkiPtr)
                    return try body(&mcFogInfo)
                }
            }
        }
    }
}

extension AccountKey.FogInfo: CStructWrapper {
    typealias CStruct = McAccountKeyFogInfo

    func withUnsafeCStructPointer<R>(
        _ body: (UnsafePointer<McAccountKeyFogInfo>) throws -> R
    ) rethrows -> R {
        try McAccountKeyFogInfo.withUnsafePointer(
            reportUrl: reportUrlString,
            reportId: reportId,
            authoritySpki: authoritySpki,
            body: body)
    }
}

extension PublicAddress: CStructWrapper {
    typealias CStruct = McPublicAddress

    func withUnsafeCStructPointer<R>(
        _ body: (UnsafePointer<McPublicAddress>) throws -> R
    ) rethrows -> R {
        try viewPublicKey.asMcBuffer { viewKeyBufferPtr in
            try spendPublicKey.asMcBuffer { spendKeyBufferPtr in
                try fogInfo.withUnsafeCStructPointer { fogInfoPtr in
                    var publicAddress = McPublicAddress(
                        view_public_key: viewKeyBufferPtr,
                        spend_public_key: spendKeyBufferPtr,
                        fog_info: fogInfoPtr)
                    return try body(&publicAddress)
                }
            }
        }
    }
}

extension PublicAddress.FogInfo: CStructWrapper {
    typealias CStruct = McPublicAddressFogInfo

    func withUnsafeCStructPointer<R>(
        _ body: (UnsafePointer<McPublicAddressFogInfo>) throws -> R
    ) rethrows -> R {
        try reportUrlString.withCString { reportUrlPtr in
            try reportId.withCString { reportIdPtr in
                try authoritySig.asMcBuffer { authoritySigPtr in
                    var mcFogInfo = McPublicAddressFogInfo(
                        report_url: reportUrlPtr,
                        report_id: reportIdPtr,
                        authority_sig: authoritySigPtr)
                    return try body(&mcFogInfo)
                }
            }
        }
    }
}
