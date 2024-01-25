//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
#if canImport(LibMobileCoinHTTP)
import LibMobileCoinCommon
import LibMobileCoinHTTP
#endif
import SwiftProtobuf

protocol AttestedHttpCallable: HttpCallable {
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
    ) -> Result < (responseAad: InnerResponseAad, response: InnerResponse),
                AttestedHttpConnectionError>
}

extension AttestedHttpCallable where InnerRequestAad == (), InnerRequest == Request {
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Request, AeadError> {
        .success(request)
    }
}

extension AttestedHttpCallable where InnerResponseAad == (), InnerResponse == Response {
    func processResponse(response: Response, attestAkeCipher: AttestAke.Cipher)
        -> Result < (responseAad: InnerResponseAad, response: InnerResponse),
                  AttestedHttpConnectionError>
    {
        .success((responseAad: (), response: response))
    }
}

extension AttestedHttpCallable
    where InnerRequestAad == (),
        Request == Attest_Message,
        InnerRequest: InfallibleDataSerializable
{
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Attest_Message, AeadError> {
        let aad = Data()
        let plaintext = request.serializedDataInfallible

        return attestAkeCipher.encryptMessage(aad: aad, plaintext: plaintext)
    }
}

extension AttestedHttpCallable
    where InnerResponseAad == (),
        Response == Attest_Message,
        InnerResponse: Message
{
    func processResponse(
        response: Attest_Message,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result < (responseAad: InnerResponseAad, response: InnerResponse),
                AttestedHttpConnectionError>
    {
//        guard response.aad == Data() else {
//            return .failure(.connectionError(.invalidServerResponse(
//                "\(Self.self) received unexpected aad: " +
//                    "\(redacting: response.aad.base64EncodedString()), message: " +
//                    "\(redacting: response.serializedDataInfallible.base64EncodedString())")))
//        }

        return attestAkeCipher.decryptMessage(response)
            .mapError { _ in .attestationFailure() }
            .flatMap { plaintext in
                guard let response = try? InnerResponse(serializedData: plaintext) else {
                    return .failure(.connectionError(.invalidServerResponse(
                        "Failed to deserialized attested message plaintext into " +
                            "\(InnerResponse.self). plaintext: " +
                            "\(redacting: plaintext.base64EncodedString())")))
                }

                return .success((responseAad: (), response: response))
            }
    }
}

extension AttestedHttpCallable
    where InnerRequestAad: InfallibleDataSerializable,
        Request == Attest_Message,
        InnerRequest: InfallibleDataSerializable
{
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result<Attest_Message, AeadError> {
        let aad = requestAad.serializedDataInfallible
        let plaintext = request.serializedDataInfallible

        return attestAkeCipher.encryptMessage(aad: aad, plaintext: plaintext)
    }
}

extension AttestedHttpCallable
    where InnerResponseAad: Message,
        Response == Attest_Message,
        InnerResponse: Message
{
    func processResponse(
        response: Attest_Message,
        attestAkeCipher: AttestAke.Cipher
    ) -> Result < (responseAad: InnerResponseAad, response: InnerResponse),
                AttestedHttpConnectionError>
    {
        guard let responseAad = try? InnerResponseAad(serializedData: response.aad) else {
            return .failure(.connectionError(.invalidServerResponse(
                "Failed to deserialized attested message aad into \(InnerResponseAad.self). aad: " +
                    "\(redacting: response.aad.base64EncodedString())")))
        }

        return attestAkeCipher.decryptMessage(response)
            .mapError { _ in .attestationFailure() }
            .flatMap { plaintext in
                guard let plaintextResponse = try? InnerResponse(serializedData: plaintext) else {
                    return .failure(.connectionError(.invalidServerResponse(
                        "Failed to deserialized attested message plaintext into " +
                            "\(InnerResponse.self). plaintext: " +
                            "\(redacting: plaintext.base64EncodedString())")))
                }

                return .success((responseAad: responseAad, response: plaintextResponse))
            }
    }
}
