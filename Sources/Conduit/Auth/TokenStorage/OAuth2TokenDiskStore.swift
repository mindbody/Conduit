//
//  OAuth2TokenDiskStore.swift
//  Conduit
//
//  Created by John Hammerlund on 10/14/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Stores and retrieves OAuth2 tokens from local storage (unencrypted)
@available(*, deprecated, message: "OAuth2TokenDiskStore is no longer supported. Please migrate to OAuth2TokenUserDefaultsStore or OAuth2TokenFileStore.")
public class OAuth2TokenDiskStore: OAuth2TokenStore {

    /// The strategy by which the token is stored locally
    public enum StorageMethod {
        /// Stores the token to NSUserDefaults
        case userDefaults
        /// Stores the token to the provided local file URL
        case url(URL)
    }

    private let storageMethod: StorageMethod

    /// Creates a new OAuth2TokenDiskStore
    /// - Parameters:
    ///   - storageMethod: The strategy by which the token is stored locally
    public init(storageMethod: StorageMethod) {
        self.storageMethod = storageMethod
    }

    @discardableResult
    public func store<Token: OAuth2Token & DataConvertible>(token: Token?, for client: OAuth2ClientConfiguration,
                                                            with authorization: OAuth2Authorization) -> Bool {
        let tokenData: Data?
        if let token = token {
            tokenData = try? token.serialized()
        }
        else {
            tokenData = nil
        }
        switch storageMethod {
        case .userDefaults:
            let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
            let userDefaults = UserDefaults.standard
            userDefaults.set(tokenData, forKey: identifier)
            return userDefaults.synchronize()
        case .url(let storageURL):
            if let tokenData = tokenData {
                do {
                    let directoryPath = storageURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: [:])
                    try tokenData.write(to: storageURL, options: [.atomic])
                    return true
                }
                catch {
                    return false
                }
            }
            else {
                do {
                    try FileManager.default.removeItem(at: storageURL)
                    return true
                }
                catch {
                    return false
                }
            }
        }
    }

    public func tokenFor<Token: OAuth2Token & DataConvertible>(client: OAuth2ClientConfiguration,
                                                               authorization: OAuth2Authorization) -> Token? {
        switch storageMethod {
        case .userDefaults:
            let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
            guard let data = UserDefaults.standard.object(forKey: identifier) as? Data else {
                return nil
            }
            return try? Token(serializedData: data)
        case .url(let storageURL):
            guard let data = FileManager.default.contents(atPath: storageURL.path) else {
                return nil
            }
            return try? Token(serializedData: data)
        }
    }

    public func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        switch storageMethod {
        case .userDefaults:
            let userDefaultsStore = OAuth2TokenUserDefaultsStore(userDefaults: .standard)
            return userDefaultsStore.lockRefreshToken(timeout: timeout, client: client, authorization: authorization)
        case .url:
            /// Unsupported; OAuth2TokenDiskStore only references a single path for token storage
            return false
        }
    }

    public func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        switch storageMethod {
        case .userDefaults:
            let userDefaultsStore = OAuth2TokenUserDefaultsStore(userDefaults: .standard)
            return userDefaultsStore.unlockRefreshTokenFor(client: client, authorization: authorization)
        case .url:
            /// Unsupported; OAuth2TokenDiskStore only references a single path for token storage
            return false
        }
    }

    public func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
        switch storageMethod {
        case .userDefaults:
            let userDefaultsStore = OAuth2TokenUserDefaultsStore(userDefaults: .standard)
            return userDefaultsStore.refreshTokenLockExpirationFor(client: client, authorization: authorization)
        case .url:
            /// Unsupported; OAuth2TokenDiskStore only references a single path for token storage
            return nil
        }
    }

}
