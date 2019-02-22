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

    func tokenData<Token>(from token: Token?) -> Data? where Token: DataConvertible, Token: OAuth2Token {
        guard let token = token else {
            return nil
        }
        if let cipher = tokenCipher {
            return try? cipher.encrypt(token: token)
        }
        return try? token.serialized()
    }

    func token<Token>(from data: Data) -> Token? where Token: DataConvertible, Token: OAuth2Token {
        if let cipher = tokenCipher {
            return try? cipher.decrypt(data: data)
        }
        return try? Token(serializedData: data)

    }

}
