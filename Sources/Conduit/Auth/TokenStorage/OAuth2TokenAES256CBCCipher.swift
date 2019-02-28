//
//  OAuth2TokenEncryptor.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// AES-256 Cipher Block Chaining OAuth2 token dipher
///
/// Use in conjunction with `OAuth2TokenEncryptedStore` as follows:
///
///     let store = OAuth2TokenUserDefaultsStore()
///     store.tokenCipher = OAuth2TokenAES256CBCCipher(passphrase: passphrase, salt: salt)
///
/// A secure encryption key is generated from the given passphrase and salt. The CBC IV is
/// automatically generated and persisted together with the encrypted token.
///
/// Once the store token cipher has been set up, all stored tokens will be
/// automatically encrypted by the store via `encrypt(token:)`.
///
///     store.store(token: myToken, ...) // automatic encryption
///
/// Retrieved tokens will be autimatically decrypted by the store via `decrypt(token:)`:
///
///     let token: BearerToken? = store.token(for: ...) // automatic decryption
///
public final class OAuth2TokenAES256CBCCipher: OAuth2TokenCipher {

    let cipher: AES256CBCCipher

    /// Initialize token cipher with a give passphrase.
    ///
    /// - Parameters:
    ///   - passphrase: Passphrase used for encryption
    ///   - salt: Salt used for encryption
    /// - Throws: Exception if derivated key cannot be generated from passphrase
    public init(passphrase: String, salt: String) throws {
        cipher = try AES256CBCCipher(passphrase: passphrase, salt: salt)
    }

    /// Securely encrypt an `OAuth2Token` with AES-256 CBC
    ///
    /// - Parameter token: Token to encrypt
    /// - Returns: Ciphertext data with encrypted token
    /// - Throws: Exception if encryption failed
    public func encrypt<Token>(token: Token) throws -> Data where Token: DataConvertible, Token: OAuth2Token {
        let tokenData = try token.serialized()
        return try cipher.encrypt(data: tokenData)
    }

    /// Securely decrypt AES-256 CBC encrypted tokens
    ///
    /// - Parameter cipherData: Ciphertext data containing the encrypted token
    /// - Returns: Decrypted `OAuth2Token`
    /// - Throws: Exception if decryption failed
    public func decrypt<Token>(data cipherData: Data) throws -> Token where Token: DataConvertible, Token: OAuth2Token {
        let data = try cipher.decrypt(data: cipherData)
        return try Token(serializedData: data)
    }
}
