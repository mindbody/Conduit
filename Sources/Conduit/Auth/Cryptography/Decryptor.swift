//
//  Decryptor.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import Foundation

/// A type that decrypts ciphertext to plaintext data
public protocol Decryptor {
    /// Decrypts the ciphertext
    /// - Parameter data: The ciphertext data
    /// - Returns: The decrypted plaintext data
    /// - Throws: A `CryptorError` if an error is encountered
    func decrypt(data: Data) throws -> Data
}
