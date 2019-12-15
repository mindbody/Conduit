//
//  OAuth2TokenCryptorCipher.swift
//  Conduit
//
//  Created by John Hammerlund on 12/11/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// A token cipher that delegates encryption/decryption to an `Encryptor` and `Decryptor`.
///
/// Use in conjunction with `OAuth2TokenEncryptedStore` as follows:
///
///     let store = OAuth2TokenUserDefaultsStore()
///     let aesCipher = AES256CBCCipher(passphrase: passphrase, salt: salt)
///     store.tokenCipher = OAuth2TokenCryptoCipher(cipher: cipher)
///
/// Once the store token cipher has been set up, all stored tokens will be
/// automatically encrypted by the store via `encrypt(token:)`.
///
///     store.store(token: myToken, ...) // automatic encryption
///
/// Retrieved tokens will be automatically decrypted by the store via `decrypt(token:)`:
///
///     let token: BearerToken? = store.token(for: ...) // automatic decryption
///
/// - Note: If previously-written token data is not encrypted, then the token will still be provided and a warning will be logged.
public final class OAuth2TokenCryptoCipher: OAuth2TokenCipher {

    private let encryptor: Encryptor
    private let decryptor: Decryptor

    /// Creates a new `OAuth2TokenCryptoCipher`
    /// - Parameter encryptor: Encrypts the token data for storage
    /// - Parameter decryptor: Decrypts the token ciphertext from storage
    public init(encryptor: Encryptor, decryptor: Decryptor) {
        self.encryptor = encryptor
        self.decryptor = decryptor
    }

    /// Creates a new `OAuth2TokenCryptoCipher`
    /// - Parameter cipher: Encrypts the token data for storage & decrypts the token ciphertext from storage
    public convenience init(cipher: Encryptor & Decryptor) {
        self.init(encryptor: cipher, decryptor: cipher)
    }

    public func encrypt<Token>(token: Token) throws -> Data where Token: DataConvertible, Token: OAuth2Token {
        let tokenData = try token.serialized()
        return try encryptor.encrypt(data: tokenData)
    }

    public func decrypt<Token>(data: Data) throws -> Token where Token: DataConvertible, Token: OAuth2Token {
        do {
            let decryptedData = try decryptor.decrypt(data: data)
            return try Token(serializedData: decryptedData)
        }
        catch {
            if let token = try? Token(serializedData: data) {
                logger.warn("OAuth2TokenCryptoCipher: Token data not decrypted (possible migration)")
                return token
            }
            throw error
        }
    }

}
