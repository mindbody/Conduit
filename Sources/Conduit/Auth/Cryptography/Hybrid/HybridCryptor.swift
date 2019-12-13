//
//  HybridCryptor.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

#if XCFRAMEWORK

import Foundation
import Security

/// Encrypts / decrypts data with a symmetric key and encrypts the symmetric key with PKE. The
/// resulting ciphertext includes blocks for the the encrypted symmetric key and the encrypted data.
/// This gives us the power and security of asymmetric algorithms with the speed of symmetric encryption/decryption.
@available(OSXApplicationExtension 10.12.1, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
public final class HybridCryptor: Encryptor, Decryptor {

    private let keyProvider: HybridKeyProvider

    /// Creates a new `HybridCryptor`
    ///
    /// - Parameters:
    ///   - keyProvider: Provides an asymmetric key-pair for encrypting/decrypting the symmetric session key
    public init(keyProvider: HybridKeyProvider) {
        self.keyProvider = keyProvider
    }

    public func encrypt(data: Data) throws -> Data {
        let publicKey = try keyProvider.makeKeyPair().publicKey
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, keyProvider.keyAlgorithm) else {
            throw CryptoError(code: .cryptoOperationUnsupported, detail: "Cannot encrypt using \(keyProvider.keyAlgorithm)")
        }
        var encryptionError: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey, keyProvider.keyAlgorithm, data as CFData, &encryptionError) else {
            if let error = encryptionError?.takeRetainedValue() {
                throw CryptoError(code: .encryptionFailed, detail: "\(error.localizedDescription)")
            }
            throw CryptoError(code: .encryptionFailed)
        }
        return encryptedData as Data
    }

    public func decrypt(data: Data) throws -> Data {
        let privateKey = try keyProvider.makeKeyPair().privateKey
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, keyProvider.keyAlgorithm) else {
           throw CryptoError(code: .cryptoOperationUnsupported, detail: "Cannot decrypt using \(keyProvider.keyAlgorithm)")
        }
        var decryptionError: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey, keyProvider.keyAlgorithm, data as CFData, &decryptionError) else {
            if let error = decryptionError?.takeRetainedValue() {
                throw CryptoError(code: .decryptionFailed, detail: "\(error.localizedDescription)")
            }
            throw CryptoError(code: .decryptionFailed)
        }
        return decryptedData as Data
    }

}

#endif
