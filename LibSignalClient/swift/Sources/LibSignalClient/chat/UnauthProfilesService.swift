//
// Copyright 2026 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public protocol UnauthProfilesService: Sendable {
    /// Does an account with the given ACI or PNI exist?
    ///
    /// Throws only if the request can't be completed.
    func accountExists(_ account: ServiceId) async throws -> Bool

    /// Fetches a profile key credential using the given request context.
    ///
    /// - Throws:
    ///   - ``SignalError/requestUnauthorized(_:)`` if the profile key does not match the access key
    ///     stored on the server.
    ///   - ``SignalError/profileNotFound(_:)`` if the account in question does not exist or does not
    ///     have a profile (possible if they have not finished setting up their account).
    ///     Check ``accountExists(_:)`` if you need to distinguish between these possibilities.
    ///   - the standard Signal network errors
    func getProfileKeyCredential(
        requestContext: ProfileKeyCredentialRequestContext,
        serverParams: ServerPublicParams
    ) async throws -> ExpiringProfileKeyCredential
}

extension UnauthenticatedChatConnection: UnauthProfilesService {
    public func accountExists(_ account: ServiceId) async throws -> Bool {
        return try await NativeNice.UnauthenticatedChatConnection_account_exists(
            asyncContext: self.tokioAsyncContext,
            chat: self,
            account: account
        )
    }

    public func getProfileKeyCredential(
        requestContext: ProfileKeyCredentialRequestContext,
        serverParams: ServerPublicParams
    ) async throws -> ExpiringProfileKeyCredential {
        return try await NativeNice.UnauthenticatedChatConnection_get_profile_key_credential(
            asyncContext: self.tokioAsyncContext,
            chat: self,
            profileKeyRequestContext: requestContext,
            serverParams: serverParams
        )
    }
}

extension UnauthServiceSelector where Self == UnauthServiceSelectorHelper<any UnauthProfilesService> {
    public static var profiles: Self { .init() }
}
