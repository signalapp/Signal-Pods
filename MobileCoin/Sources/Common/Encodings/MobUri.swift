//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

public enum MobUri {
    public enum Payload {
        case publicAddress(PublicAddress)
        case paymentRequest(PaymentRequest)
        case transferPayload(TransferPayload)
    }

    public static func decode(uri uriString: String) -> Result<Payload, InvalidInputError> {
        guard let uri = URL(string: uriString) else {
            logger.info("Could not parse MobURI as URL: \(redacting: uriString)")
            return .failure(
                InvalidInputError("Could not parse MobUri as URL: \(redacting: uriString)"))
        }
        guard let scheme = uri.scheme else {
            logger.info("MobUri scheme cannot be empty.")
            return .failure(InvalidInputError("MobUri scheme cannot be empty."))
        }
        guard scheme == McConstants.MOB_URI_SCHEME else {
            logger.info(
                "MobUri scheme must be \"\(McConstants.MOB_URI_SCHEME)\". Found: \(scheme)")
            return .failure(InvalidInputError(
                "MobUri scheme must be \"\(McConstants.MOB_URI_SCHEME)\". Found: \(scheme)"))
        }

        return Payload.make(pathComponents: uri.pathComponents)
    }

    public static func encode(_ publicAddress: PublicAddress) -> String {
        encode(.publicAddress(publicAddress))
    }

    public static func encode(_ paymentRequest: PaymentRequest) -> String {
        encode(.paymentRequest(paymentRequest))
    }

    public static func encode(_ transferPayload: TransferPayload) -> String {
        encode(.transferPayload(transferPayload))
    }

    static func encode(_ payload: Payload) -> String {
        "\(McConstants.MOB_URI_SCHEME)://\(payload.uriPath)"
    }
}

extension MobUri.Payload {
    static func make(pathComponents: [String]) -> Result<MobUri.Payload, InvalidInputError> {
        // Foundation.URL returns "/" as the first value in pathComponents, so we normalize by
        // removing it.
        guard let firstComponent = pathComponents.first else {
            return .failure(InvalidInputError("MobUri must have a path."))
        }
        guard firstComponent == "/" else {
            return .failure(InvalidInputError("MobUri must have an absolute path."))
        }
        let pathComponents = Array(pathComponents.dropFirst())

        guard pathComponents.count >= 2 else {
            return .failure(InvalidInputError("MobUri must have at least 2 path components."))
        }
        let payloadTypeString = pathComponents[0]

        guard let payloadType = PayloadType(payloadTypeString) else {
            return .failure(InvalidInputError(
                "MobUri contains unrecognized payload type: \(payloadTypeString)"))
        }

        switch payloadType {
        case .b58:
            let payloadString = pathComponents[1]
            guard let decodingResult = Base58Coder.decode(payloadString) else {
                return .failure(InvalidInputError(
                    "MobUri payload base-58 decoding failed. Payload: \(redacting: payloadString)"))
            }

            return .success(MobUri.Payload(decodingResult))
        }
    }

    init(_ base58DecodingResult: Base58DecodingResult) {
        switch base58DecodingResult {
        case .publicAddress(let publicAddress):
            self = .publicAddress(publicAddress)
        case .paymentRequest(let paymentRequest):
            self = .paymentRequest(paymentRequest)
        case .transferPayload(let transferPayload):
            self = .transferPayload(transferPayload)
        }
    }

    var payloadType: PayloadType {
        switch self {
        case .publicAddress, .paymentRequest, .transferPayload:
            return .b58
        }
    }

    var payloadString: String {
        switch self {
        case .publicAddress(let publicAddress):
            return Base58Coder.encode(publicAddress)
        case .paymentRequest(let paymentRequest):
            return Base58Coder.encode(paymentRequest)
        case .transferPayload(let transferPayload):
            return Base58Coder.encode(transferPayload)
        }
    }

    var uriPath: String {
        "/\(payloadType)/\(payloadString)"
    }
}

extension MobUri.Payload {
    enum PayloadType {
        case b58

        init?(_ string: String) {
            switch string {
            case "b58":
                self = .b58
            default:
                return nil
            }
        }
    }
}

extension MobUri.Payload.PayloadType: CustomStringConvertible {
    var description: String {
        switch self {
        case .b58:
            return "b58"
        }
    }

}
