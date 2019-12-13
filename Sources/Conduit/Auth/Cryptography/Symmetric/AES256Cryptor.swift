//
//  AES256Cryptor.swift
//  Conduit
//
//  Created by John Hammerlund on 12/11/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// Encrypts / decrypts data using AES-256
public final class AES256Cryptor: Encryptor, Decryptor {

    private let cipher: AES256CBCCipher

    /// Creates a new `AES256Cryptor`
    /// - Parameter cipher: The underlying AES-256 cipher
    public init(cipher: AES256CBCCipher) {
        self.cipher = cipher
    }

    /// Creates a new `AES256Cryptor`
    /// - Parameter passphrase: Passphrase string to use for encryption key derivation
    /// - Parameter salt: Salt to be used for key derivation
    public convenience init(passphrase: String, salt: String) throws {
        let cipher = try AES256CBCCipher(passphrase: passphrase, salt: salt)
        self.init(cipher: cipher)
    }

    public func encrypt(data: Data) throws -> Data {
        do {
            return try cipher.encrypt(data: data)
        }
        catch let error as AES256CBCCipher.Error {
            switch error {
            case .encryptionError:
                throw CryptoError(code: .encryptionFailed)
            default:
                throw CryptoError(code: .internalOperationFailed, detail: error.localizedDescription)
            }
        }
    }

    public func decrypt(data: Data) throws -> Data {
        do {
            return try cipher.decrypt(data: data)
        }
        catch let error as AES256CBCCipher.Error {
            switch error {
            case .decryptionError:
                throw CryptoError(code: .decryptionFailed)
            default:
                throw CryptoError(code: .internalOperationFailed, detail: error.localizedDescription)
            }
        }
    }

}
