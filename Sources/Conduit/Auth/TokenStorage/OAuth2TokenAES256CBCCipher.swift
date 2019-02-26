//
//  OAuth2TokenEncryptor.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation
import CommonCrypto

public final class OAuth2TokenAES256CBCCipher: OAuth2TokenCipher {

    let keyLength = kCCKeySizeAES256
    let blockSize = kCCBlockSizeAES128
    let encryptionKey: Data
    let initializationVector: Data

    public enum CipherError: Error {
        case invalidKey
        case invalidInitializationVector
        case encryptionError
        case decryptionError
    }

    public init(key: String, iv vector: String) throws {
        guard key.utf8.count == 32, let keyData = key.data(using: .utf8) else {
            throw CipherError.invalidKey
        }
        guard vector.utf8.count == 16, let ivData = vector.data(using: .utf8) else {
            throw CipherError.invalidInitializationVector
        }

        encryptionKey = keyData
        initializationVector = ivData
    }

    public func encrypt<Token>(token: Token) throws -> Data where Token: DataConvertible, Token: OAuth2Token {
        let tokenData = try token.serialized()
        let cipherTextLength = size_t(tokenData.count + blockSize) // Add an extra block for padding

        // Output
        var cipherTextData = Data(count: cipherTextLength)
        var numBytesEncrypted: size_t = 0

        let status = cipherTextData.withUnsafeMutableBytes { cipherTextBytes in
            CCCrypt(CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    Array(encryptionKey),
                    keyLength,
                    Array(initializationVector),
                    Array(tokenData),
                    tokenData.count,
                    cipherTextBytes,
                    cipherTextLength,
                    &numBytesEncrypted)
        }

        if status == kCCSuccess {
            cipherTextData.count = numBytesEncrypted
        }
        else {
            throw CipherError.encryptionError
        }
        return cipherTextData
    }

    public func decrypt<Token>(data cipherData: Data) throws -> Token where Token: DataConvertible, Token: OAuth2Token {
        let outputLength = size_t(cipherData.count)

        // Output
        var outputData = Data(count: outputLength)
        var numBytesDecrypted: size_t = 0

        let status = outputData.withUnsafeMutableBytes { outputBytes in
            CCCrypt(CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    Array(encryptionKey),
                    encryptionKey.count,
                    Array(initializationVector),
                    Array(cipherData),
                    cipherData.count,
                    outputBytes,
                    outputLength,
                    &numBytesDecrypted)
        }

        if status == kCCSuccess {
            outputData.count = numBytesDecrypted
        }
        else {
            throw CipherError.decryptionError
        }
        return try Token(serializedData: outputData)
    }
}
