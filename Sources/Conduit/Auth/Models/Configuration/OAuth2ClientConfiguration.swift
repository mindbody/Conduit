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

    /// Whether the client is public, i.e. it holds no client secret. A public client sends its
    /// `client_id` in the token request body and omits the `Authorization: Basic` header across every
    /// grant type, and supports only bearer client-level authorization (a client-level basic request
    /// fails, as there is no secret to send). A confidential client (the default) is unchanged. Set
    /// only through the public-client initializer.
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
    /// The client authenticates by sending its `client_id` in the token request body and omits the
    /// `Authorization: Basic` header.
    /// - Parameters:
    ///   - publicClientIdentifier: The OAuth2 client identifier
    ///   - environment: The OAuth2 server application environment that the client communicates with
    ///   - guestUsername: The guest user's username, if one exists or is needed for client-level authorization
    ///   - guestPassword: The guest user's password, if one exists or is needed for client-level authorization
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

    /// The `BasicToken` for client authentication, or `nil` for a public client, which authenticates
    /// with `client_id` in the request body instead. Reading through `isPublicClient` keeps a public
    /// client from ever emitting a Basic header, even if a secret was mistakenly assigned.
    var basicToken: BasicToken? {
        guard !isPublicClient else {
            return nil
        }
        return BasicToken(username: clientIdentifier, password: clientSecret)
    }
}
