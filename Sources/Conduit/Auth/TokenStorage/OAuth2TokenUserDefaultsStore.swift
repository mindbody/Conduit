//
//  OAuth2TokenUserDefaultsStore.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// Stores and retrieves OAuth2 tokens from UserDefaults
public class OAuth2TokenUserDefaultsStore: OAuth2TokenStore {

    private let userDefaults: UserDefaults
    private let context: String

    /// Creates a new OAuth2TokenUserDefaultsStore
    ///
    /// - Parameters:
    ///   - userDefaults: The `UserDefaults` used for storage. Defaults to `UserDefaults.standard`
    ///   - context: A context for sandboxing user defaults keys
    public init(userDefaults: UserDefaults = .standard, context: String = "") {
        self.userDefaults = userDefaults
        self.context = context
    }

    public func store<Token>(token: Token?, for client: OAuth2ClientConfiguration,
                             with authorization: OAuth2Authorization) -> Bool where Token: DataConvertible, Token: OAuth2Token {
        let tokenData: Data?
        if let token = token {
            tokenData = try? token.serialized()
        }
        else {
            tokenData = nil
        }

        let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        userDefaults.set(tokenData, forKey: sandboxedIdentifier(identifier: identifier))
        return userDefaults.synchronize()
    }

    public func tokenFor<Token>(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization)
        -> Token? where Token: DataConvertible, Token: OAuth2Token {
        let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        guard let data = userDefaults.object(forKey: sandboxedIdentifier(identifier: identifier)) as? Data else {
            return nil
        }
        return try? Token(serializedData: data)
    }

    public func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        let identifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        let expiration = Date().addingTimeInterval(timeout).timeIntervalSince1970
        userDefaults.set(expiration, forKey: sandboxedIdentifier(identifier: identifier))
        return userDefaults.synchronize()
    }

    public func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        let identifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        userDefaults.removeObject(forKey: sandboxedIdentifier(identifier: identifier))
        return userDefaults.synchronize()
    }

    public func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
        let identifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        let timestamp = userDefaults.double(forKey: sandboxedIdentifier(identifier: identifier))
        if timestamp == 0 {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    func sandboxedIdentifier(identifier: String) -> String {
        if context.isEmpty {
            return identifier
        }
        return "\(context):::\(identifier)"
    }
}
