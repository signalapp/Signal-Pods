//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinCommon)
import LibMobileCoinCommon
#endif

// TrustedIdentities
final class AttestationVerifier {
    private let ptr: OpaquePointer

    init(attestation: Attestation) {
        // Safety: mc_verifier_create should never return nil.
        self.ptr = withMcInfallible(mc_trusted_identities_create)

        attestation.mrEnclaves.forEach(addMrEnclave)
        attestation.mrSigners.forEach(addMrSigner)
    }

    deinit {
        mc_trusted_identities_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }

    private func addMrEnclave(_ mrEnclave: Attestation.MrEnclave) {
        let ffiMrEnclaveVerifier = MrEnclaveVerifier(mrEnclave: mrEnclave)
        ffiMrEnclaveVerifier.withUnsafeOpaquePointer { ffiMrEnclaveVerifierPtr in
            // Safety: mc_trusted_identities_add_mr_enclave should never fail.
            withMcInfallible { mc_trusted_identities_add_mr_enclave(ptr, ffiMrEnclaveVerifierPtr) }
        }
    }

    private func addMrSigner(_ mrSigner: Attestation.MrSigner) {
        let ffiMrSignerVerifier = MrSignerVerifier(mrSigner: mrSigner)
        ffiMrSignerVerifier.withUnsafeOpaquePointer { ffiMrSignerVerifierPtr in
            // Safety: mc_trusted_identities_add_mr_signer should never fail.
            withMcInfallible { mc_trusted_identities_add_mr_signer(ptr, ffiMrSignerVerifierPtr) }
        }
    }
}

// TrustedMrEnclaveIdentity
private final class MrEnclaveVerifier {
    private let ptr: OpaquePointer

    init(mrEnclave: Attestation.MrEnclave) {
        let configAdvisories = withMcInfallible(mc_advisories_create)
        mrEnclave.allowedConfigAdvisories.forEach { advisory_id in
            withMcInfallible { mc_add_advisory(configAdvisories, advisory_id) }
        }

        let hardeningAdvisories = withMcInfallible(mc_advisories_create)
        mrEnclave.allowedHardeningAdvisories.forEach { advisory_id in
            withMcInfallible { mc_add_advisory(hardeningAdvisories, advisory_id) }
        }

        self.ptr = mrEnclave.mrEnclave.asMcBuffer { mrEnclavePtr in
            // Safety: mc_mr_enclave_verifier_create should never fail.
            withMcInfallible {
                mc_trusted_identity_mr_enclave_create(
                    mrEnclavePtr,
                    configAdvisories,
                    hardeningAdvisories
                )
            }
        }
    }

    deinit {
        mc_trusted_identity_mr_enclave_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }
}

// TrustedMrSignerIdentity
private final class MrSignerVerifier {
    private let ptr: OpaquePointer

    init(mrSigner: Attestation.MrSigner) {
        let configAdvisories = withMcInfallible(mc_advisories_create)
        mrSigner.allowedConfigAdvisories.forEach { advisory_id in
            withMcInfallible { mc_add_advisory(configAdvisories, advisory_id) }
        }

        let hardeningAdvisories = withMcInfallible(mc_advisories_create)
        mrSigner.allowedHardeningAdvisories.forEach { advisory_id in
            withMcInfallible { mc_add_advisory(hardeningAdvisories, advisory_id) }
        }

        self.ptr = mrSigner.mrSigner.asMcBuffer { mrSignerPtr in
            // Safety: mc_mr_signer_verifier_create should never fail.
            withMcInfallible {
                mc_trusted_identity_mr_signer_create(
                    mrSignerPtr,
                    configAdvisories,
                    hardeningAdvisories,
                    mrSigner.productId,
                    mrSigner.minimumSecurityVersion)
            }
        }
    }

    deinit {
        mc_trusted_identity_mr_signer_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        try body(ptr)
    }
}
