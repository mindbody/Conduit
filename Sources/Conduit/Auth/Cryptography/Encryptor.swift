//
//  Encryptor.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation

/// A type that encrypts data into ciphertext
public protocol Encryptor {
    /// Encrypts the provided data
    /// - Parameter data: The plaintext data to encrypt
    /// - Returns: The resulting ciphertext
    /// - Throws: A `CryptorError` if an error is encountered
    func encrypt(data: Data) throws -> Data
}
