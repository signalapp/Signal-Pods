//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

// swiftlint:disable multiline_function_chains

import Foundation

public struct Attestation {
    static func make(
        mrSigner: Data,
        productId: UInt16,
        minimumSecurityVersion: UInt16,
        allowedConfigAdvisories: [String] = [],
        allowedHardeningAdvisories: [String] = []
    ) -> Result<Attestation, InvalidInputError> {
        logger.info("")
        return MrSigner.make(
            mrSigner: mrSigner,
            productId: productId,
            minimumSecurityVersion: minimumSecurityVersion,
            allowedConfigAdvisories: allowedConfigAdvisories,
            allowedHardeningAdvisories: allowedHardeningAdvisories
        ).map { mrSigner in
            Attestation(mrSigners: [mrSigner])
        }
    }

    let mrEnclaves: [MrEnclave]
    let mrSigners: [MrSigner]

    public init(_ mrSigner: MrSigner) {
        logger.info("")
        self.init(mrEnclaves: [], mrSigners: [mrSigner])
    }

    public init(mrEnclaves: [MrEnclave] = [], mrSigners: [MrSigner] = []) {
        logger.info("")
        self.mrEnclaves = mrEnclaves
        self.mrSigners = mrSigners
    }

    init(
        mrSigner: Data32,
        productId: UInt16,
        minimumSecurityVersion: UInt16,
        allowedConfigAdvisories: [String] = [],
        allowedHardeningAdvisories: [String] = []
    ) {
        logger.info("")
        let mrSigner = MrSigner(
            mrSigner: mrSigner,
            productId: productId,
            minimumSecurityVersion: minimumSecurityVersion,
            allowedConfigAdvisories: allowedConfigAdvisories,
            allowedHardeningAdvisories: allowedHardeningAdvisories)
        self.init(mrSigners: [mrSigner])
    }
}

extension Attestation: CustomStringConvertible {
    public var description: String {
        var params: [String] = []
        if mrEnclaves.count == 1 && mrSigners.isEmpty, let mrEnclave = mrEnclaves.first {
            params.append("\(mrEnclave)")
        } else if mrSigners.count == 1 && mrEnclaves.isEmpty, let mrSigner = mrSigners.first {
            params.append("\(mrSigner)")
        } else {
            if !mrEnclaves.isEmpty {
                params.append("mrEnclaves: \(mrEnclaves)")
            }
            if !mrSigners.isEmpty {
                params.append("mrSigners: \(mrSigners)")
            }
        }
        return "Attestation(\(params.joined(separator: ", ")))"
    }
}

extension Attestation {
    public struct MrEnclave {
        let mrEnclave: Data32
        let allowedConfigAdvisories: [String]
        let allowedHardeningAdvisories: [String]

        /// - Returns: `InvalidInputError` when `mrEnclave` is not 32 bytes in length.
        public static func make(
            mrEnclave: Data,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) -> Result<MrEnclave, InvalidInputError> {
            logger.info("")
            guard let mrEnclave32 = Data32(mrEnclave) else {
                logger.info("""
                    failure - mrEnclave must be 32 bytes in length. \
                    \(mrEnclave.count) != 32
                    """)
                return .failure(InvalidInputError("mrEnclave must be " +
                    "32 bytes in length. \(mrEnclave.count) != 32"))
            }
            return .success(MrEnclave(
                mrEnclave: mrEnclave32,
                allowedConfigAdvisories: allowedConfigAdvisories,
                allowedHardeningAdvisories: allowedHardeningAdvisories))
        }

        init(
            mrEnclave: Data32,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) {
            logger.info("")
            self.mrEnclave = mrEnclave
            self.allowedConfigAdvisories = allowedConfigAdvisories
            self.allowedHardeningAdvisories = allowedHardeningAdvisories
        }
    }
}

extension Attestation.MrEnclave: CustomStringConvertible {
    public var description: String {
        var params = ["0x\(mrEnclave.hexEncodedString())"]
        if !allowedConfigAdvisories.isEmpty {
            params.append("allowedConfigAdvisories: \(allowedConfigAdvisories)")
        }
        if !allowedHardeningAdvisories.isEmpty {
            params.append("allowedHardeningAdvisories: \(allowedHardeningAdvisories)")
        }
        return "MrEnclave(\(params.joined(separator: ", ")))"
    }
}

extension Attestation {
    public struct MrSigner {
        let mrSigner: Data32
        let productId: UInt16
        let minimumSecurityVersion: UInt16
        let allowedConfigAdvisories: [String]
        let allowedHardeningAdvisories: [String]

        /// - Returns: `InvalidInputError` when `mrSigner` is not 32 bytes in length.
        public static func make(
            mrSigner: Data,
            productId: UInt16,
            minimumSecurityVersion: UInt16,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) -> Result<MrSigner, InvalidInputError> {
            logger.info("")
            guard let mrSigner32 = Data32(mrSigner) else {
                logger.info("""
                    failure - mrSigner must be 32 bytes in length. \
                    \(mrSigner.count) != 32
                    """)
                return .failure(InvalidInputError("mrSigner must be " +
                    "32 bytes in length. \(mrSigner.count) != 32"))
            }

            return .success(MrSigner(
                mrSigner: mrSigner32,
                productId: productId,
                minimumSecurityVersion: minimumSecurityVersion,
                allowedConfigAdvisories: allowedConfigAdvisories,
                allowedHardeningAdvisories: allowedHardeningAdvisories))
        }

        init(
            mrSigner: Data32,
            productId: UInt16,
            minimumSecurityVersion: UInt16,
            allowedConfigAdvisories: [String] = [],
            allowedHardeningAdvisories: [String] = []
        ) {
            logger.info("")
            self.mrSigner = mrSigner
            self.productId = productId
            self.minimumSecurityVersion = minimumSecurityVersion
            self.allowedConfigAdvisories = allowedConfigAdvisories
            self.allowedHardeningAdvisories = allowedHardeningAdvisories
        }
    }
}

extension Attestation.MrSigner: CustomStringConvertible {
    public var description: String {
        var params = [
            "0x\(mrSigner.hexEncodedString())",
            "productId: \(productId)",
            "minimumSecurityVersion: \(minimumSecurityVersion)",
        ]
        if !allowedConfigAdvisories.isEmpty {
            params.append("allowedConfigAdvisories: \(allowedConfigAdvisories)")
        }
        if !allowedHardeningAdvisories.isEmpty {
            params.append("allowedHardeningAdvisories: \(allowedHardeningAdvisories)")
        }
        return "MrSigner(\(params.joined(separator: ", ")))"
    }
}
