//
//  OAuth2TokenKeychainStore.swift
//  Conduit
//
//  Created by John Hammerlund on 7/11/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Stores and retrieves OAuth2 tokens from the device keychain
public struct OAuth2TokenKeychainStore: OAuth2TokenStore {

    private let service: String
    private let accessGroup: String?

    /// A keychain accessibility constant for defining when the token may be accessed or written
    public var keychainAccessibility = kSecAttrAccessibleWhenUnlocked

    /// Creates a new OAuth2TokenKeychainStore
    /// - Parameters:
    ///   - service: The keychain service (kSecAttrService)
    ///   - accessGroup: The keychain access group identifier (kSecAttrAccessGroup)
    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    @discardableResult
    public func store<Token: DataConvertible & OAuth2Token>(token: Token?, for client: OAuth2ClientConfiguration,
                                                            with authorization: OAuth2Authorization) -> Bool {

        let account = accountIdentifierFor(authorization, clientConfiguration: client)
        let keychainWrapper = KeychainWrapper(serviceName: service, accessGroup: accessGroup)
        if let token = token {
            logger.debug("Storing token to keychain for account: \(account), service: \(service), " +
                         "accessGroup: \(accessGroup ?? "N/A")")
            if let data = try? token.serialized() {
                return keychainWrapper.setData(data, forKey: account)
            }
            return false
        }
        else {
            logger.debug("Deleting stored token from keychain for account: \(account), service: \(service), " +
                         "accessGroup: \(accessGroup ?? "N/A")")
            return keychainWrapper.removeObject(forKey: account)
        }
    }

    public func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                               authorization: OAuth2Authorization) -> Token? {
        let keychainWrapper = KeychainWrapper(serviceName: service, accessGroup: accessGroup)
        let account = accountIdentifierFor(authorization, clientConfiguration: client)
        guard let data = keychainWrapper.data(forKey: account) else {
            return nil
        }
        return try? Token(serializedData: data)
    }

    private func accountIdentifierFor(_ authorization: OAuth2Authorization,
                                      clientConfiguration: OAuth2ClientConfiguration) -> String {
        let authorizationLevel = authorization.level == .user ? "user-token" : "client-token"
        return [
            "com.mindbodyonline.connect.oauth-client",
            clientConfiguration.clientIdentifier,
            authorizationLevel,
            authorization.type.rawValue
        ].joined(separator: ".")
    }
}
