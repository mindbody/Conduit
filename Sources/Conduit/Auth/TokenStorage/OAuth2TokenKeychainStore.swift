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

    /// A keychain accessibility constant for defining when the token may be accessed or written.
    /// Defaults to kSecAttrAccessibleWhenUnlocked.
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
        var options: KeychainItemOptions?
        if let accessibilityItem = keychainItemAccessibilityFrom(accessibilyAttribute: keychainAccessibility) {
            options = KeychainItemOptions(itemAccessibility: accessibilityItem)
        }

        if let token = token {
            logger.debug("Storing token to keychain for account: \(account), service: \(service), " +
                         "accessGroup: \(accessGroup ?? "N/A")")
            if let data = try? token.serialized() {
                return keychainWrapper.setData(data, forKey: account, withOptions: options)
            }
            return false
        }
        else {
            logger.debug("Deleting stored token from keychain for account: \(account), service: \(service), " +
                         "accessGroup: \(accessGroup ?? "N/A")")
            return keychainWrapper.removeObject(forKey: account, withOptions: options)
        }
    }

    public func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                               authorization: OAuth2Authorization) -> Token? {
        let keychainWrapper = KeychainWrapper(serviceName: service, accessGroup: accessGroup)
        let account = accountIdentifierFor(authorization, clientConfiguration: client)
        var options: KeychainItemOptions?
        if let accessibilityItem = keychainItemAccessibilityFrom(accessibilyAttribute: keychainAccessibility) {
            options = KeychainItemOptions(itemAccessibility: accessibilityItem)
        }

        guard let data = keychainWrapper.data(forKey: account, withOptions: options) else {
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

    private func keychainItemAccessibilityFrom(accessibilyAttribute: CFString) -> KeychainItemAccessibility? {
        let accessibilityItems: [CFString: KeychainItemAccessibility] = [
            kSecAttrAccessibleAfterFirstUnlock: .afterFirstUnlock,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly: .afterFirstUnlockThisDeviceOnly,
            kSecAttrAccessibleAlways: .always,
            kSecAttrAccessibleAlwaysThisDeviceOnly: .alwaysThisDeviceOnly,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly: .whenPasscodeSetThisDeviceOnly,
            kSecAttrAccessibleWhenUnlocked: .whenUnlocked,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly: .whenUnlockedThisDeviceOnly
        ]
        return accessibilityItems[accessibilyAttribute]
    }
}
