//
//  TokenMigrator.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/20/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// Migrate tokens from source to destination
///
/// This migrator is useful to move tokens from one store to another (eg. Keychain to UserDefaults).
/// Another use case can be move tokens from one configuration to another (eg. Auth v1 to Auth v2).
///
/// - `source` and `destination` can have different `store` or the same.
/// - `source` and `destination` can have different `configuration` or the same.
///
/// - warning: If both `store` and `configuration` are the same for `source` and `destination`,
///            all stored tokens will be lost. This is a limitation from `OAuth2TokenStore` not
///            conforming to `Equatable`.
public struct TokenMigrator {
    public let source: Configuration
    public let destination: Configuration

    /// Migrate tokens from `source` to `destinatiion`
    /// - Parameters:
    ///   - source: Source configuration
    ///   - destination: Destination configuration
    public init(source: Configuration, destination: Configuration) {
        self.source = source
        self.destination = destination
    }

    /// Migrate stored tokens for all authorization levels and types
    public func migrateAllTokens() {
        let allAuthorizations = [
            OAuth2Authorization(type: .basic, level: .client),
            OAuth2Authorization(type: .bearer, level: .client),
            OAuth2Authorization(type: .basic, level: .user),
            OAuth2Authorization(type: .bearer, level: .user)
        ]

        allAuthorizations.forEach(migrateToken)
    }

    /// Migrate stored token for a give authorization level and type
    /// - Parameter authorization: OAuth2 authorization
    public func migrateToken(for authorization: OAuth2Authorization) {
        if let token: BearerToken = source.tokenStore.tokenFor(client: source.clientConfiguration, authorization: authorization) {
            destination.tokenStore.store(token: token, for: destination.clientConfiguration, with: authorization)
        }
        source.tokenStore.removeTokenFor(client: source.clientConfiguration, authorization: authorization)
    }
}

// MARK: - Migration Configuration

extension TokenMigrator {
    public struct Configuration {
        public let tokenStore: OAuth2TokenStore
        public let clientConfiguration: OAuth2ClientConfiguration

        /// Migration configuration for a token store and OAuth2 client configuration
        /// - Parameters:
        ///   - tokenStore: OAuth2 token store
        ///   - clientConfiguration: OAuth2 client configuration
        public init(tokenStore: OAuth2TokenStore, clientConfiguration: OAuth2ClientConfiguration) {
            self.tokenStore = tokenStore
            self.clientConfiguration = clientConfiguration
        }
    }
}
