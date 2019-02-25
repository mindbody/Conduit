//
//  OAuth2Authorization.swift
//  Conduit
//
//  Created by John Hammerlund on 7/29/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Describes the type and level of authorization needed for a request
public struct OAuth2Authorization: Equatable {

    /// The authorization token type
    /// - Bearer: An access token issued from a server application
    /// - Basic: A plaintext identifier and secret, usually for authenticating a client
    public enum AuthorizationType: String {
        case bearer
        case basic
    }

    /// The level of authorization needed for the request
    /// - User: Requires an authorized user
    /// - Client: Requires the authorized client
    public enum AuthorizationLevel {
        case user
        case client
    }

    /// The authorization token type
    public let type: AuthorizationType

    /// The level of authorization needed for the request
    public let level: AuthorizationLevel

    /// Creats a new OAuth2Authorization
    /// - Parameters:
    ///   - type: The authorization token type
    ///   - level: The level of authorization needed for the request
    public init(type: AuthorizationType, level: AuthorizationLevel) {
        self.type = type
        self.level = level
    }
}
