//
//  AES256CBCCipher.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation
import CommonCrypto

public final class AES256CBCCipher {

    let encryptionKey: [UInt8]

    public enum CipherError: Error {
        case invalidKey
        case encryptionError
        case decryptionError
    }

    public convenience init(key: String) throws {
        guard let keyData = key.data(using: .utf8) else {
            throw CipherError.invalidKey
        }
        try self.init(key: Array(keyData))
    }

    public init(key: [UInt8]) throws {
        guard key.count == 32 else {
            throw CipherError.invalidKey
        }
        encryptionKey = key
    }

    /// AES 256-bit CBC encryption
    ///
    /// Encrypt data with AES 256 CBC.
    /// Cipher data is prefixed with the initialization vector:
    ///
    ///     VVVV VVVV VVVV VVVV DDDD DDDD DDDD DDDD DDDD DDDD DDDD DDDD ...
    ///     \_______ IV ______/ \_ Cipher Block 1_/ \_ Cipher Block 2_/
    ///
    /// Initialization Vector (IV) length is equivalent to a cipher
    /// block (kCCBlockSizeAES128 == 16 bytes). This length is
    /// independent of the key length (kCCKeySizeAES256 == 32 bytes).
    ///
    /// - Parameters:
    ///   - data: Data to be encrypted
    ///   - vector: Optional initialization vector (defaults to random vector)
    /// - Returns: Encrypted data prefixed with IV
    /// - Throws: Exception if encryption failed
    public func encrypt(data: Data, iv vector: Data? = nil) throws -> Data {
        let initializationVector = vector.flatMap(Array.init) ?? randomInitializationVector
        let cipherTextLength = data.count + kCCBlockSizeAES128 // Buffer padding

        // Output buffer
        var cipherTextData = Data(count: cipherTextLength)
        var numBytesEncrypted = 0

        let status = cipherTextData.withUnsafeMutableBytes { cipherTextBytes in
            CCCrypt(CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    encryptionKey,
                    kCCKeySizeAES256,
                    initializationVector,
                    Array(data),
                    data.count,
                    cipherTextBytes,
                    cipherTextLength,
                    &numBytesEncrypted)
        }
        guard status == kCCSuccess else {
            throw CipherError.encryptionError
        }

        cipherTextData.count = numBytesEncrypted
        return Data(bytes: initializationVector) + cipherTextData
    }

    /// AES 256-bit CBC decryption
    ///
    /// Decrypt cipher data previously encrypted with AES 256 CBC.
    /// Cipher data must be prefixed with the initialization vector:
    ///
    ///     VVVV VVVV VVVV VVVV DDDD DDDD DDDD DDDD DDDD DDDD DDDD DDDD ...
    ///     \_______ IV ______/ \_ Cipher Block 1_/ \_ Cipher Block 2_/
    ///
    /// - Parameter cipherData: Cipher data with IV prefix
    /// - Returns: Decrypted data
    /// - Throws: Exception if decryption failed
    public func decrypt(data cipherData: Data) throws -> Data {
        let initializationVector = Array(cipherData.prefix(kCCBlockSizeAES128))
        let cipherTextBytes = Array(cipherData.suffix(from: kCCBlockSizeAES128))
        let outputLength = cipherData.count - kCCBlockSizeAES128

        // Output buffer
        var outputData = Data(count: outputLength)
        var numBytesDecrypted = 0

        let status = outputData.withUnsafeMutableBytes { outputBytes in
            CCCrypt(CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    encryptionKey,
                    kCCKeySizeAES256,
                    initializationVector,
                    cipherTextBytes,
                    outputLength,
                    outputBytes,
                    outputLength,
                    &numBytesDecrypted)
        }
        guard status == kCCSuccess else {
            throw CipherError.decryptionError
        }

        outputData.count = numBytesDecrypted // Discard any padding
        return outputData
    }

    /// Generate a random 128bit (16 byte) initialization vector
    var randomInitializationVector: [UInt8] {
        return (0...15).map { _ in UInt8.random(in: 0...UInt8.max) }
    }
}
