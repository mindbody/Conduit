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

    /// The OAuth2 client secret
    public var clientSecret: String

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
}
