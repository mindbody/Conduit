//
//  OAuth2TokenEncryptedStore.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/22/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// A type that provides the ability to store and retrieve OAuth2 tokens with encryption support
public protocol OAuth2TokenEncryptedStore: OAuth2TokenStore {

    /// Optional token cipher to be used when persisting and retrieving tokens
    var tokenCipher: OAuth2TokenCipher? { get set }
}

extension OAuth2TokenEncryptedStore {

    /// Serialize data using encryption if a cipher has been provided
    ///
    /// - Parameter token: Token to serialize
    /// - Returns: Serialized/encrypted token
    public func tokenData<Token>(from token: Token?) -> Data? where Token: DataConvertible, Token: OAuth2Token {
        guard let token = token else {
            return nil
        }
        if let cipher = tokenCipher {
            return try? cipher.encrypt(token: token)
        }
        return try? token.serialized()
    }

    /// Deserialize token using decryption if a cipher has been provided
    ///
    /// - Parameter data: Serialized token
    /// - Returns: Deserialized/decrypted token
    public func token<Token>(from data: Data) -> Token? where Token: DataConvertible, Token: OAuth2Token {
        if let cipher = tokenCipher, let token: Token = try? cipher.decrypt(data: data) {
            return token
        }
        return try? Token(serializedData: data)
    }
}
