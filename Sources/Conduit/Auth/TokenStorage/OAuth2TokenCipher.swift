//
//  OAuth2TokenCipher.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/22/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// Token cipher interface for encryption/decryption of tokens used with `OAuth2TokenEncryptedStore`
public protocol OAuth2TokenCipher {

    /// Token encryption
    ///
    /// - Parameter token: `OAuth2Token` to be encrypted
    /// - Returns: Encrypted ciphertext with token contents
    /// - Throws: Exception if token encryption failed
    func encrypt<Token>(token: Token) throws -> Data where Token: DataConvertible, Token: OAuth2Token

    /// Token decryption
    ///
    /// - Parameter data: Ciphertext containing the token to be decrypted
    /// - Returns: Decrypted `OAuth2Token`
    /// - Throws: Exception if token decryption failed
    func decrypt<Token>(data: Data) throws -> Token where Token: DataConvertible, Token: OAuth2Token
}
