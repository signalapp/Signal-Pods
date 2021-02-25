//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin
import SwiftProtobuf

protocol AttestedGrpcCallable: GrpcCallable {
    associatedtype InnerRequestAad = ()
    associatedtype InnerRequest
    associatedtype InnerResponseAad = ()
    associatedtype InnerResponse

    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) throws -> Request

    func processResponse(
        response: Response,
        attestAkeCipher: AttestAke.Cipher
    ) throws -> (responseAad: InnerResponseAad, response: InnerResponse)
}

extension AttestedGrpcCallable where InnerRequestAad == (), InnerRequest == Request {
    func processRequest(
        requestAad: InnerRequestAad,
        request: InnerRequest,
        attestAkeCipher: AttestAke.Cipher
    ) throws -> Request {
        request
    }
}

extension AttestedGrpcCallable where InnerResponseAad == (), InnerResponse == Response {
    func processResponse(response: Response, attestAkeCipher: AttestAke.Cipher) throws
        -> (responseAad: InnerResponseAad, response: InnerResponse)
    {
        (responseAad: (), response: response)
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
    ) throws -> Attest_Message {
        let aad = Data()
        let plaintext: Data
        do {
            plaintext = try request.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            fatalError("Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }

        return try attestAkeCipher.encryptMessage(aad: aad, plaintext: plaintext)
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
    ) throws -> (responseAad: InnerResponseAad, response: InnerResponse) {
        guard response.aad == Data() else {
            throw ConnectionFailure("\(Self.self) received unexpected aad: " +
                "\(response.aad.base64EncodedString()), message: \(response)")
        }

        let plaintext = try attestAkeCipher.decryptMessage(response)
        let response = try InnerResponse(serializedData: plaintext)
        return (responseAad: (), response: response)
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
    ) throws -> Attest_Message {
        let aad: Data
        let plaintext: Data
        do {
            aad = try requestAad.serializedData()
            plaintext = try request.serializedData()
        } catch {
            // Safety: Protobuf binary serialization is no fail when not using proto2 or `Any`
            fatalError("Error: \(Self.self).\(#function): Protobuf serialization failed: \(error)")
        }

        return try attestAkeCipher.encryptMessage(aad: aad, plaintext: plaintext)
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
    ) throws -> (responseAad: InnerResponseAad, response: InnerResponse) {
        let plaintext = try attestAkeCipher.decryptMessage(response)
        let plaintextResponse = try InnerResponse(serializedData: plaintext)
        let responseAad = try InnerResponseAad(serializedData: response.aad)
        return (responseAad: responseAad, response: plaintextResponse)
    }
}
