//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class AttestationVerifier {
    private let ptr: OpaquePointer

    init(attestation: Attestation) {
        logger.info("")
        // Safety: mc_verifier_create should never return nil.
        self.ptr = withMcInfallible(mc_verifier_create)

        attestation.mrEnclaves.forEach(addMrEnclave)
        attestation.mrSigners.forEach(addMrSigner)
    }

    deinit {
        logger.info("")
        mc_verifier_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        logger.info("")
        return try body(ptr)
    }

    private func addMrEnclave(_ mrEnclave: Attestation.MrEnclave) {
        logger.info("")
        let ffiMrEnclaveVerifier = MrEnclaveVerifier(mrEnclave: mrEnclave)
        ffiMrEnclaveVerifier.withUnsafeOpaquePointer { ffiMrEnclaveVerifierPtr in
            // Safety: mc_verifier_add_mr_enclave should never fail.
            withMcInfallible { mc_verifier_add_mr_enclave(ptr, ffiMrEnclaveVerifierPtr) }
        }
    }

    private func addMrSigner(_ mrSigner: Attestation.MrSigner) {
        logger.info("")
        let ffiMrSignerVerifier = MrSignerVerifier(mrSigner: mrSigner)
        ffiMrSignerVerifier.withUnsafeOpaquePointer { ffiMrSignerVerifierPtr in
            // Safety: mc_verifier_add_mr_signer should never fail.
            withMcInfallible { mc_verifier_add_mr_signer(ptr, ffiMrSignerVerifierPtr) }
        }
    }
}

private final class MrEnclaveVerifier {
    private let ptr: OpaquePointer

    init(mrEnclave: Attestation.MrEnclave) {
        logger.info("")
        self.ptr = mrEnclave.mrEnclave.asMcBuffer { mrEnclavePtr in
            // Safety: mc_mr_enclave_verifier_create should never fail.
            withMcInfallible { mc_mr_enclave_verifier_create(mrEnclavePtr) }
        }

        mrEnclave.allowedConfigAdvisories.forEach(addConfigAdvisory)
        mrEnclave.allowedHardeningAdvisories.forEach(addHardeningAdvisory)
    }

    deinit {
        logger.info("")
        mc_mr_enclave_verifier_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        logger.info("")
        return try body(ptr)
    }

    private func addConfigAdvisory(advisoryId: String) {
        logger.info("")
        advisoryId.withCString { advisoryIdPtr in
            // Safety: mc_mr_enclave_verifier_allow_config_advisory should never fail.
            withMcInfallible { mc_mr_enclave_verifier_allow_config_advisory(ptr, advisoryIdPtr) }
        }
    }

    private func addHardeningAdvisory(advisoryId: String) {
        logger.info("")
        advisoryId.withCString { advisoryIdPtr in
            // Safety: mc_mr_enclave_verifier_allow_hardening_advisory should never fail.
            withMcInfallible { mc_mr_enclave_verifier_allow_hardening_advisory(ptr, advisoryIdPtr) }
        }
    }
}

private final class MrSignerVerifier {
    private let ptr: OpaquePointer

    init(mrSigner: Attestation.MrSigner) {
        logger.info("")
        self.ptr = mrSigner.mrSigner.asMcBuffer { mrSignerPtr in
            // Safety: mc_mr_signer_verifier_create should never fail.
            withMcInfallible {
                mc_mr_signer_verifier_create(
                    mrSignerPtr,
                    mrSigner.productId,
                    mrSigner.minimumSecurityVersion)
            }
        }

        mrSigner.allowedConfigAdvisories.forEach(addConfigAdvisory)
        mrSigner.allowedHardeningAdvisories.forEach(addHardeningAdvisory)
    }

    deinit {
        logger.info("")
        mc_mr_signer_verifier_free(ptr)
    }

    func withUnsafeOpaquePointer<R>(_ body: (OpaquePointer) throws -> R) rethrows -> R {
        logger.info("")
        return try body(ptr)
    }

    private func addConfigAdvisory(advisoryId: String) {
        logger.info("")
        advisoryId.withCString { advisoryIdPtr in
            // Safety: mc_mr_signer_verifier_allow_config_advisory should never fail.
            withMcInfallible { mc_mr_signer_verifier_allow_config_advisory(ptr, advisoryIdPtr) }
        }
    }

    private func addHardeningAdvisory(advisoryId: String) {
        logger.info("")
        advisoryId.withCString { advisoryIdPtr in
            // Safety: mc_mr_signer_verifier_allow_hardening_advisory should never fail.
            withMcInfallible { mc_mr_signer_verifier_allow_hardening_advisory(ptr, advisoryIdPtr) }
        }
    }
}
