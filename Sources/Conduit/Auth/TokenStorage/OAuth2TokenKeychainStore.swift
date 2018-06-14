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
    private let keychainWrapper: KeychainWrapper
    private let keychainItemOptions: KeychainItemOptions?

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
        self.keychainWrapper = KeychainWrapper(serviceName: service, accessGroup: accessGroup)
        if let accessibilityItem = OAuth2TokenKeychainStore.keychainItemAccessibilityFrom(accessibilyAttribute: keychainAccessibility) {
            self.keychainItemOptions = KeychainItemOptions(itemAccessibility: accessibilityItem)
        }
        else {
            self.keychainItemOptions = nil
        }
    }

    @discardableResult
    public func store<Token: DataConvertible & OAuth2Token>(token: Token?, for client: OAuth2ClientConfiguration,
                                                            with authorization: OAuth2Authorization) -> Bool {
        let account = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        if let token = token {
            logger.debug("Storing token to keychain for account: \(account), service: \(service), " +
                         "accessGroup: \(accessGroup ?? "N/A")")
            if let data = try? token.serialized() {
                return keychainWrapper.setData(data, forKey: account, withOptions: keychainItemOptions)
            }
            return false
        }
        else {
            logger.debug("Deleting stored token from keychain for account: \(account), service: \(service), " +
                         "accessGroup: \(accessGroup ?? "N/A")")
            return keychainWrapper.removeObject(forKey: account, withOptions: keychainItemOptions)
        }
    }

    public func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                               authorization: OAuth2Authorization) -> Token? {
        let account = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        guard let data = keychainWrapper.data(forKey: account, withOptions: keychainItemOptions) else {
            return nil
        }
        return try? Token(serializedData: data)
    }

    public func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        let account = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        let timestamp = Date().addingTimeInterval(timeout).timeIntervalSince1970
        return keychainWrapper.setDouble(timestamp, forKey: account, withOptions: keychainItemOptions)
    }

    public func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        let account = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        return keychainWrapper.removeObject(forKey: account, withOptions: keychainItemOptions)
    }

    public func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
        let account = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        guard let timestamp = keychainWrapper.double(forKey: account, withOptions: keychainItemOptions) else {
            return nil
        }
        let expiration = Date(timeIntervalSince1970: timestamp)
        return expiration
    }

    private static func keychainItemAccessibilityFrom(accessibilyAttribute: CFString) -> KeychainItemAccessibility? {
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
