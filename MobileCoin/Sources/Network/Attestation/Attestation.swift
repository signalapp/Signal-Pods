//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

// swiftlint:disable line_length multiline_function_chains

import Foundation

public struct Attestation {
    let mrEnclaves: [MrEnclave]
    let mrSigners: [MrSigner]

    public init(_ mrSigner: MrSigner) {
        self.init(mrEnclaves: [], mrSigners: [mrSigner])
    }

    public init(mrEnclaves: [MrEnclave] = [], mrSigners: [MrSigner] = []) {
        self.mrEnclaves = mrEnclaves
        self.mrSigners = mrSigners
    }

    // Maintainer note: Deprecated publicly, but not internally.
    @available(*, deprecated, renamed: "init(mrEnclaves:mrSigners:)")
    public init(
        mrSigner: Data,
        productId: UInt16,
        minimumSecurityVersion: UInt16,
        allowedConfigAdvisories: [String] = [],
        allowedHardeningAdvisories: [String] = []
    ) throws {
        let mrSigner = try MrSigner(
            mrSigner: mrSigner,
            productId: productId,
            minimumSecurityVersion: minimumSecurityVersion,
            allowedConfigAdvisories: allowedConfigAdvisories,
            allowedHardeningAdvisories: allowedHardeningAdvisories)
        self.init(mrSigners: [mrSigner])
    }

    init(
        mrSigner: Data32,
        productId: UInt16,
        minimumSecurityVersion: UInt16,
        allowedConfigAdvisories: [String] = [],
        allowedHardeningAdvisories: [String] = []
    ) {
        let mrSigner = MrSigner(
            mrSigner: mrSigner,
            productId: productId,
            minimumSecurityVersion: minimumSecurityVersion,
            allowedConfigAdvisories: allowedConfigAdvisories,
            allowedHardeningAdvisories: allowedHardeningAdvisories)
        self.init(mrSigners: [mrSigner])
    }
}

extension Attestation {
    public struct MrEnclave {
        let mrEnclave: Data32
        let allowedConfigAdvisories: [String]
        let allowedHardeningAdvisories: [String]

        /// - Returns: `MalformedInput` when `mrEnclave` is not 32 bytes in length.
        public static func make(
            mrEnclave: Data,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) -> Result<MrEnclave, MalformedInput> {
            guard let mrEnclave32 = Data32(mrEnclave) else {
                return .failure(MalformedInput("\(Self.self).\(#function): mrEnclave must be 32 " +
                    "bytes in length. \(mrEnclave.count) != 32"))
            }
            return .success(Self(
                mrEnclave: mrEnclave32,
                allowedConfigAdvisories: allowedConfigAdvisories,
                allowedHardeningAdvisories: allowedHardeningAdvisories))
        }

        @available(*, deprecated, renamed:
            "Attestation.MrEnclave.make(mrEnclave:allowedConfigAdvisories:allowedHardeningAdvisories:)")
        public init(
            mrEnclave: Data,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) throws {
            self = try Self.make(
                mrEnclave: mrEnclave,
                allowedConfigAdvisories: allowedConfigAdvisories,
                allowedHardeningAdvisories: allowedHardeningAdvisories).get()
        }

        init(
            mrEnclave: Data32,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) {
            self.mrEnclave = mrEnclave
            self.allowedConfigAdvisories = allowedConfigAdvisories
            self.allowedHardeningAdvisories = allowedHardeningAdvisories
        }
    }
}

extension Attestation {
    public struct MrSigner {
        let mrSigner: Data32
        let productId: UInt16
        let minimumSecurityVersion: UInt16
        let allowedConfigAdvisories: [String]
        let allowedHardeningAdvisories: [String]

        /// - Returns: `MalformedInput` when `mrSigner` is not 32 bytes in length.
        public static func make(
            mrSigner: Data,
            productId: UInt16,
            minimumSecurityVersion: UInt16,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) -> Result<MrSigner, MalformedInput> {
            guard let mrSigner32 = Data32(mrSigner) else {
                return .failure(MalformedInput("\(Self.self).\(#function): mrSigner must be 32 " +
                    "bytes in length. \(mrSigner.count) != 32"))
            }

            return .success(Self(
                mrSigner: mrSigner32,
                productId: productId,
                minimumSecurityVersion: minimumSecurityVersion,
                allowedConfigAdvisories: allowedConfigAdvisories,
                allowedHardeningAdvisories: allowedHardeningAdvisories))
        }

        @available(*, deprecated, renamed:
            "Attestation.MrSigner.make(mrSigner:productId:minimumSecurityVersion:allowedConfigAdvisories:allowedHardeningAdvisories:)")
        public init(
            mrSigner: Data,
            productId: UInt16,
            minimumSecurityVersion: UInt16,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) throws {
            self = try Self.make(
                mrSigner: mrSigner,
                productId: productId,
                minimumSecurityVersion: minimumSecurityVersion,
                allowedConfigAdvisories: allowedConfigAdvisories,
                allowedHardeningAdvisories: allowedHardeningAdvisories).get()
        }

        init(
            mrSigner: Data32,
            productId: UInt16,
            minimumSecurityVersion: UInt16,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) {
            self.mrSigner = mrSigner
            self.productId = productId
            self.minimumSecurityVersion = minimumSecurityVersion
            self.allowedConfigAdvisories = allowedConfigAdvisories
            self.allowedHardeningAdvisories = allowedHardeningAdvisories
        }
    }
}
