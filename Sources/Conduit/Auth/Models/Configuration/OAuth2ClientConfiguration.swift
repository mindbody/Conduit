//
//  OAuth2ClientConfiguration.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Describes the configuration of an OAuth2 client, which is usually an app or app extension
public struct OAuth2ClientConfiguration: Equatable {

    /// The OAuth2 client identifier
    public var clientIdentifier: String

    /// The OAuth2 client secret. Empty for a public client (see `isPublicClient`); do not assign a
    /// non-empty secret to a public client, as it will not be sent.
    public var clientSecret: String

    /// Whether the client is public, i.e. it holds no client secret. A public client identifies itself
    /// with `client_id` in the token request body and omits the `Authorization: Basic` header across
    /// every grant type. Client-level authorization needs guest credentials (password grant); client-level
    /// basic and the `client_credentials` grant both need a secret and fail with
    /// `OAuth2Error.internalFailure`. A confidential client (the default) is unchanged. Set only through
    /// the public-client initializer.
    public private(set) var isPublicClient: Bool = false

    /// The guest user's username, if one exists or is needed for client-level authorization
    public var guestUsername: String?

    /// The guest user's password, if one exists or is needed for client-level authorization
    public var guestPassword: String?

    /// The OAuth2 server application environment that the client communicates with
    public var environment: OAuth2ServerEnvironment

    /// Creates a new OAuth2ClientConfiguration
    /// - Parameters:
    ///   - clientIdentifier: The OAuth2 client identifier
    ///   - clientSecret: The OAuth2 client secret
    ///   - environment: The OAuth2 server application environment that the client communicates with
    ///   - guestUsername: The guest user's username, if one exists or is needed for client-level authorization
    ///   - guestPassword: The guest user's password, if one exists or is needed for client-level authorization
    public init(clientIdentifier: String,
                clientSecret: String,
                environment: OAuth2ServerEnvironment,
                guestUsername: String? = nil,
                guestPassword: String? = nil) {
        self.clientIdentifier = clientIdentifier
        self.clientSecret = clientSecret
        self.guestUsername = guestUsername
        self.guestPassword = guestPassword
        self.environment = environment
    }

    /// Creates a new OAuth2ClientConfiguration for a public client, i.e. one that holds no client secret.
    /// The client identifies itself with `client_id` in the token request body and omits the
    /// `Authorization: Basic` header; `client_id` is identification, not authentication (RFC 6749 §3.2.1).
    ///
    /// A public client using the `authorization_code` grant has no code-to-client binding, so the
    /// authorization server must enforce PKCE (RFC 8252 §6): send `code_challenge` through
    /// `OAuth2AuthorizationRequest.additionalParameters` and `code_verifier` through
    /// `OAuth2AuthorizationCodeTokenGrantStrategy.tokenGrantRequestAdditionalBodyParameters`.
    ///
    /// Client-level authorization requires guest credentials: without them the `client_credentials`
    /// grant would be sent with no credential at all, which RFC 6749 §4.4 reserves for confidential
    /// clients, so the request fails with `OAuth2Error.internalFailure` instead.
    /// - Parameters:
    ///   - publicClientIdentifier: The OAuth2 client identifier
    ///   - environment: The OAuth2 server application environment that the client communicates with
    ///   - guestUsername: The guest user's username, required for client-level authorization
    ///   - guestPassword: The guest user's password, required for client-level authorization
    public init(publicClientIdentifier: String,
                environment: OAuth2ServerEnvironment,
                guestUsername: String? = nil,
                guestPassword: String? = nil) {
        self.init(clientIdentifier: publicClientIdentifier,
                  clientSecret: "",
                  environment: environment,
                  guestUsername: guestUsername,
                  guestPassword: guestPassword)
        self.isPublicClient = true
    }

    /// The `BasicToken` for client authentication, or `nil` for a public client, which identifies itself
    /// with `client_id` in the request body instead. Reading through `isPublicClient` keeps a public
    /// client from ever emitting a Basic header, even if a secret was mistakenly assigned.
    var basicToken: BasicToken? {
        guard !isPublicClient else {
            return nil
        }
        return BasicToken(username: clientIdentifier, password: clientSecret)
    }
}
