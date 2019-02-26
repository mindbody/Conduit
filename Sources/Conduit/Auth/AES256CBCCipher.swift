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

    let keyLength = kCCKeySizeAES256
    let blockSize = kCCBlockSizeAES128
    let encryptionKey: [UInt8]
    let initializationVector: [UInt8]

    public enum CipherError: Error {
        case invalidKey
        case invalidInitializationVector
        case encryptionError
        case decryptionError
    }

    public convenience init(key: String, iv vector: String) throws {
        guard let keyData = key.data(using: .utf8) else {
            throw CipherError.invalidKey
        }
        guard let ivData = vector.data(using: .utf8) else {
            throw CipherError.invalidInitializationVector
        }
        try self.init(key: Array(keyData), iv: Array(ivData))
    }

    public init(key: [UInt8], iv vector: [UInt8]) throws {
        guard key.count == 32 else {
            throw CipherError.invalidKey
        }
        guard vector.count == 16 else {
            throw CipherError.invalidInitializationVector
        }
        encryptionKey = key
        initializationVector = vector
    }

    public func encrypt(data: Data) throws -> Data {
        let cipherTextLength = size_t(data.count + blockSize) // Add an extra block for padding

        // Output
        var cipherTextData = Data(count: cipherTextLength)
        var numBytesEncrypted: size_t = 0

        let status = cipherTextData.withUnsafeMutableBytes { cipherTextBytes in
            CCCrypt(CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    encryptionKey,
                    keyLength,
                    initializationVector,
                    Array(data),
                    data.count,
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

    public func decrypt(data cipherData: Data) throws -> Data {
        let outputLength = size_t(cipherData.count)

        // Output
        var outputData = Data(count: outputLength)
        var numBytesDecrypted: size_t = 0

        let status = outputData.withUnsafeMutableBytes { outputBytes in
            CCCrypt(CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionPKCS7Padding),
                    encryptionKey,
                    encryptionKey.count,
                    initializationVector,
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
        return outputData
    }
}
