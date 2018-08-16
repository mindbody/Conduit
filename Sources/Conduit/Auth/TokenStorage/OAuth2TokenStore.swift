//
//  OAuth2TokenStore.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// A type that provides the ability to store and retrieve OAuth2 tokens
public protocol OAuth2TokenStore {

    /// Stores the provided token for the given OAuth2 client and authorization type
    /// - Parameters:
    ///     - token: The OAuth2 token to be stored, or nil if it needs to be deleted
    ///     - client: Describes the token's OAuth2 client
    ///     - authorization: The type and level of authorization that the token is used for
    /// - Returns: A Bool indicating whether or not the storage or removal succeeded
    @discardableResult
    func store<Token: OAuth2Token & DataConvertible>(token: Token?, for client: OAuth2ClientConfiguration,
                                                     with authorization: OAuth2Authorization) -> Bool

    /// Retrieves the stored token for the given OAuth2 client and authorization type
    /// - Parameters:
    ///     - client: Describes the token's OAuth2 client
    ///     - authorization: The type and level of authorization that the token is used for
    /// - Returns: A stored token, or nil if a token doesn't exist
    func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                        authorization: OAuth2Authorization) -> Token?

    /// Signals that refresh token usage is locked
    ///
    /// - Parameters:
    ///   - timeout: The lock expiration time interval
    ///   - client: Describes the token's OAuth2 client
    ///   - authorization: The type and level of authorization that the token is used for
    /// - Returns: A Bool indicating whether or not the lock was successful
    @discardableResult
    func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration,
                          authorization: OAuth2Authorization) -> Bool

    /// Signals that refresh token usage is unlocked
    ///
    /// - Parameters:
    ///   - client: Describes the token's OAuth2 client
    ///   - authorization: The type and level of authorization that the token is used for
    /// - Returns: A Bool indicating whether or not the unlock was successful
    @discardableResult
    func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool

    /// The time at which the refresh token will be unlocked, if it is currently locked
    ///
    /// - Parameters:
    ///   - client: Describes the token's OAuth2 client
    ///   - authorization: The type and level of authorization that the token is used for
    /// - Returns: The refresh token lock expiration date, or nil if unlocked
    func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date?

}

extension OAuth2TokenStore {

    /// Removes all stored tokens for a given client
    /// - Parameters:
    ///   - client: Describes the token's OAuth2 client
    public func removeAllTokensFor(client: OAuth2ClientConfiguration) {
        let allAuthorizations = [
            OAuth2Authorization(type: .bearer, level: .user),
            OAuth2Authorization(type: .basic, level: .user),
            OAuth2Authorization(type: .bearer, level: .client),
            OAuth2Authorization(type: .basic, level: .client)
        ]

        for authorization in allAuthorizations {
            removeTokenFor(client: client, authorization: authorization)
        }
    }

    /// Removes a token from storage
    ///
    /// - Parameters:
    ///   - client: Describes the token's OAuth2 client
    ///   - authorization: The type and level of authorization that the token is used for
    public func removeTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) {
        let emptyToken: BearerToken? = nil
        store(token: emptyToken, for: client, with: authorization)
    }

    /// Determines if a refresh token is locked
    ///
    /// - Parameters:
    ///   - client: Describes the token's OAuth2 client
    ///   - authorization: The type and level of authorization that the token is used for
    /// - Returns: A Bool indicating if the refresh token is locked
    func isRefreshTokenLockedFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        guard let expiration = refreshTokenLockExpirationFor(client: client, authorization: authorization) else {
            return false
        }
        return Date() < expiration
    }

    func tokenIdentifierFor(clientConfiguration: OAuth2ClientConfiguration,
                            authorization: OAuth2Authorization) -> String {
        let authorizationLevel = authorization.level == .user ? "user-token" : "client-token"
        return [
            "com.mindbodyonline.connect.oauth-client",
            clientConfiguration.clientIdentifier,
            authorizationLevel,
            authorization.type.rawValue
            ].joined(separator: ".")
    }

    func tokenLockIdentifierFor(clientConfiguration: OAuth2ClientConfiguration,
                                authorization: OAuth2Authorization) -> String {
        let tokenIdentifier = tokenIdentifierFor(clientConfiguration: clientConfiguration, authorization: authorization)
        return [
            tokenIdentifier,
            "refresh-token-locked"
        ].joined(separator: ".")
    }
}
