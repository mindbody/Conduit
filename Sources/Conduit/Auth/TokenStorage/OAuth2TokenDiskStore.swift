//
//  OAuth2TokenDiskStore.swift
//  Conduit
//
//  Created by John Hammerlund on 10/14/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//
#if !os(Linux)
// Linux support for disk storage will be added once NSCoder usage is replaced
// with Codable/Decodable tokens since NSCoder is not fully implemented

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
    public func store(token: OAuth2Token?, for client: OAuth2ClientConfiguration,
                      with authorization: OAuth2Authorization) -> Bool {
        var tokenData: Data? = nil
        if let token = token {
            tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
        }
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

    public func tokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> OAuth2Token? {
        switch storageMethod {
        case .userDefaults:
            let identifier = identifierFor(clientConfiguration: client, authorization: authorization)
            if let data = UserDefaults.standard.object(forKey: identifier) as? Data {
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? OAuth2Token
            }
            return nil
        case .url(let storageURL):
            if let data = FileManager.default.contents(atPath: storageURL.path) {
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? OAuth2Token
            }
            return nil
        }
    }

}

#endif
