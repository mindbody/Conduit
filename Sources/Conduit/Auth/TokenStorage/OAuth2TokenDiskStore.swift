//
//  OAuth2TokenDiskStore.swift
//  Conduit
//
//  Created by John Hammerlund on 10/14/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// Stores and retrieves OAuth2 tokens from local storage (unencrypted)
public class OAuth2TokenDiskStore: OAuth2TokenStore {

    /// The strategy by which the token is stored locally
    public enum StorageMethod {
        /// Stores the token to NSUserDefaults
        case userDefaults
        /// Stores the token to the provided local file URL
        @available(tvOS, unavailable, message: "Persistent file storage is unavailable in tvOS")
        case url(URL)
    }

    private let storageMethod: StorageMethod

    /// Creates a new OAuth2TokenDiskStore
    /// - Parameters:
    ///   - storageMethod: The strategy by which the token is stored locally
    public init(storageMethod: StorageMethod) {
        self.storageMethod = storageMethod
    }

    private func identifierFor(clientConfiguration: OAuth2ClientConfiguration,
                               authorization: OAuth2Authorization) -> String {
        let authorizationLevel = authorization.level == .user ? "user-token" : "client-token"
        return [
            "com.mindbodyonline.connect.oauth-client",
            clientConfiguration.clientIdentifier,
            authorizationLevel,
            authorization.type.rawValue
        ].joined(separator: ".")
    }

    @discardableResult
    public func store<Token: OAuth2Token & DataConvertible>(token: Token?, for client: OAuth2ClientConfiguration,
                                                            with authorization: OAuth2Authorization) -> Bool {
        let tokenData = token?.serialize()
        switch storageMethod {
        case .userDefaults:
            let identifier = identifierFor(clientConfiguration: client, authorization: authorization)
            let userDefaults = UserDefaults.standard
            userDefaults.set(tokenData, forKey: identifier)
            return userDefaults.synchronize()
        case .url(let storageURL):
            if let tokenData = tokenData {
                do {
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
        let jsonDecoder = JSONDecoder()
        switch storageMethod {
        case .userDefaults:
            let identifier = identifierFor(clientConfiguration: client, authorization: authorization)
            guard let data = UserDefaults.standard.object(forKey: identifier) as? Data else {
                return nil
            }
            return Token(serializedData: data)
        case .url(let storageURL):
            guard let data = FileManager.default.contents(atPath: storageURL.path) else {
                return nil
            }
            return Token(serializedData: data)
        }
    }

}
