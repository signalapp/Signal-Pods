//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
import SwiftProtobuf

enum AttestedCallError: Error {
    case aeadError(AeadError)
    case invalidInput(String)
}

extension AttestedCallError: CustomStringConvertible {
    var description: String {
        "Attested call error: " + {
            switch self {
            case .aeadError(let innerError):
                return "\(innerError)"
            case .invalidInput(let reason):
                return "Invalid input: \(reason)"
            }
        }()
    }
}

protocol AttestedGrpcCallable: GrpcCallable {
    associatedtype InnerRequestAad = ()
    associatedtype InnerRequest
    associatedtype InnerResponseAad = ()
    associatedtype InnerResponse

    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Request, AeadError>

    func processResponse(
        response: Response,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<(responseAad: InnerResponseAad, response: InnerResponse), AttestedConnectionError>
}

extension AttestedGrpcCallable where InnerRequestAad == (), InnerRequest == Request {
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Request, AeadError> {
        .success(request)
    }
}

extension AttestedGrpcCallable where InnerResponseAad == (), InnerResponse == Response {
    func processResponse(response: Response, attestAkeCipher: AttestAke.Cipher)
        -> Result<(responseAad: InnerResponseAad, response: InnerResponse), AttestedConnectionError>
    {
        .success((responseAad: (), response: response))
    }
}

extension AttestedGrpcCallable
    where InnerRequestAad == (),
        Request == Attest_Message,
        InnerRequest: Message
{
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Attest_Message, AeadError> {
        let aad = Data()
        let plaintext: Data
        do {
            plaintext = try request.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            logger.fatalError(
                "Error: Protobuf serialization failed: \(error)")
        }

        return attestAkeCipher.encryptMessage(aad: aad, plaintext: plaintext)
    }
}

extension AttestedGrpcCallable
    where InnerResponseAad == (),
        Response == Attest_Message,
        InnerResponse: Message
{
    func processResponse(
        response: Attest_Message,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<(responseAad: InnerResponseAad, response: InnerResponse), AttestedConnectionError> {
        guard response.aad == Data() else {
            return .failure(.connectionError(.invalidServerResponse("\(Self.self) received " +
                "unexpected aad: \(response.aad.base64EncodedString()), message: \(response)")))
        }

        return attestAkeCipher.decryptMessage(response)
            .mapError { _ in .attestationFailure() }
            .flatMap { plaintext in
                let response: InnerResponse
                do {
                    response = try InnerResponse(serializedData: plaintext)
                } catch {
                    return .failure(.connectionError(
                        .invalidServerResponse("Failed to deserialize server response: \(error)")))
                }
                return .success((responseAad: (), response: response))
            }
    }
}

extension AttestedGrpcCallable
    where InnerRequestAad: Message,
        Request == Attest_Message,
        InnerRequest: Message
{
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Attest_Message, AeadError> {
        let aad: Data
        let plaintext: Data
        do {
            aad = try requestAad.serializedData()
            plaintext = try request.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            logger.fatalError(
                "Error: Protobuf serialization failed: \(error)")
        }

        return attestAkeCipher.encryptMessage(aad: aad, plaintext: plaintext)
    }
}

extension AttestedGrpcCallable
    where InnerResponseAad: Message,
        Response == Attest_Message,
        InnerResponse: Message
{
    func processResponse(
        response: Attest_Message,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<(responseAad: InnerResponseAad, response: InnerResponse), AttestedConnectionError> {
        attestAkeCipher.decryptMessage(response)
            .mapError { _ in .attestationFailure() }
            .flatMap { plaintext in
                let plaintextResponse: InnerResponse
                let responseAad: InnerResponseAad
                do {
                    plaintextResponse = try InnerResponse(serializedData: plaintext)
                    responseAad = try InnerResponseAad(serializedData: response.aad)
                } catch {
                    return .failure(.connectionError(
                        .invalidServerResponse("Failed to deserialize server response: \(error)")))
                }
                return .success((responseAad: responseAad, response: plaintextResponse))
            }
    }
}
