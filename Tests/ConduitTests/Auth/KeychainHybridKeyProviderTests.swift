//
//  KeychainHybridKeyProviderTests.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

import XCTest
@testable import Conduit

@available(macOS 10.12.1, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
final class KeychainHybridKeyProviderTests: XCTestCase {

    private lazy var plaintextData: Data = {
        guard let data = MockResource.json.data else {
            fatalError("Test setup failed")
        }
        return data
    }()

    private var prefersSecureEnclaveStorage: Bool = {
        // SEP access requires codesigning on Mac apps & therefore will fail unit tests
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }()

    func testEncryptsAndDecryptsUsingEC() throws {
        let encryptionType: HybridEncryptionType = .eceisAESGCM
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: encryptionType)
        sut.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = encryptionType.algorithm
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair = try sut.makeKeyPair()

        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair.publicKey, .encrypt, algorithm))
        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair.privateKey, .decrypt, algorithm))
    }

    func testRetrievesStoredEllipticCurveKeys() throws {
        let encryptionType: HybridEncryptionType = .eceisAESGCM
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: encryptionType)
        sut.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair1 = try sut.makeKeyPair()
        let keyPair2 = try sut.makeKeyPair()

        // Both keys should be the same, so we test that each ciphertext can be decrypted by the alternate private key

        guard let ciphertext1 = SecKeyCreateEncryptedData(keyPair1.publicKey, encryptionType.algorithm, plaintextData as CFData, nil),
            let ciphertext2 = SecKeyCreateEncryptedData(keyPair2.publicKey, encryptionType.algorithm, plaintextData as CFData, nil) else {
                XCTFail("Encryption failed")
                return
        }

        guard let decrypted1 = SecKeyCreateDecryptedData(keyPair2.privateKey, encryptionType.algorithm, ciphertext1, nil),
            let decrypted2 = SecKeyCreateDecryptedData(keyPair1.privateKey, encryptionType.algorithm, ciphertext2, nil) else {
                XCTFail("Decryption failed")
                return
        }

        XCTAssertEqual(decrypted1, decrypted2)
        XCTAssertEqual(decrypted1, plaintextData as CFData)
    }

    func testDeletesStoredEllipticCurveKeys() throws {
        let encryptionType: HybridEncryptionType = .eceisAESGCM
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: encryptionType)
        sut.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage
        sut.deleteKey()

        let keyPair1 = try sut.makeKeyPair()
        let ciphertext1 = SecKeyCreateEncryptedData(keyPair1.publicKey, encryptionType.algorithm, plaintextData as CFData, nil)

        XCTAssertTrue(sut.deleteKey())

        let keyPair2 = try sut.makeKeyPair()
        let ciphertext2 = SecKeyCreateEncryptedData(keyPair2.publicKey, encryptionType.algorithm, plaintextData as CFData, nil)

        XCTAssertNotNil(ciphertext1)
        XCTAssertNotNil(ciphertext2)
        XCTAssertNotEqual(ciphertext1, plaintextData as CFData)
        XCTAssertNotEqual(ciphertext1, ciphertext2)
    }

    func testSegmentsStoredEllipticCurveKeysByContext() throws {
        let context1 = "\(#function)-context1"
        let context2 = "\(#function)-context2"
        let encryptionType: HybridEncryptionType = .eceisAESGCM

        let provider1 = KeychainHybridKeyProvider(context: context1, encryptionType: encryptionType)
        let provider2 = KeychainHybridKeyProvider(context: context2, encryptionType: encryptionType)
        provider1.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage
        provider2.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage

        provider1.deleteKey()
        provider2.deleteKey()

        let publicKey1 = try provider1.makeKeyPair().publicKey
        let publicKey2 = try provider2.makeKeyPair().publicKey

        let ciphertext1 = SecKeyCreateEncryptedData(publicKey1, encryptionType.algorithm, plaintextData as CFData, nil)
        let ciphertext2 = SecKeyCreateEncryptedData(publicKey2, encryptionType.algorithm, plaintextData as CFData, nil)

        XCTAssertNotNil(ciphertext1)
        XCTAssertNotNil(ciphertext2)
        XCTAssertNotEqual(ciphertext1, plaintextData as CFData)
        XCTAssertNotEqual(ciphertext1, ciphertext2)
    }

    func testRetrievesStoredRSAKeys() throws {
        let encryptionType: HybridEncryptionType = .rsaAESGCM
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: encryptionType)
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256AESGCM
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair1 = try sut.makeKeyPair()
        let keyPair2 = try sut.makeKeyPair()

        // Both keys should be the same, so we test that each ciphertext can be decrypted by the alternate private key

        guard let ciphertext1 = SecKeyCreateEncryptedData(keyPair1.publicKey, encryptionType.algorithm, plaintextData as CFData, nil),
            let ciphertext2 = SecKeyCreateEncryptedData(keyPair2.publicKey, encryptionType.algorithm, plaintextData as CFData, nil) else {
                XCTFail("Encryption failed")
                return
        }

        guard let decrypted1 = SecKeyCreateDecryptedData(keyPair2.privateKey, encryptionType.algorithm, ciphertext1, nil),
            let decrypted2 = SecKeyCreateDecryptedData(keyPair1.privateKey, encryptionType.algorithm, ciphertext2, nil) else {
                XCTFail("Decryption failed")
                return
        }

        XCTAssertEqual(decrypted1, decrypted2)
        XCTAssertEqual(decrypted1, plaintextData as CFData)
    }

    func testEncryptsAndDecryptsUsingRSA() throws {
        let encryptionType: HybridEncryptionType = .rsaAESGCM
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: encryptionType)
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = encryptionType.algorithm
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair = try sut.makeKeyPair()

        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair.publicKey, .encrypt, algorithm))
        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair.privateKey, .decrypt, algorithm))
    }

    func testDeletesStoredRSAKeys() throws {
        let encryptionType: HybridEncryptionType = .rsaAESGCM
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: encryptionType)
        sut.deleteKey()

        let keyPair1 = try sut.makeKeyPair()
        let ciphertext1 = SecKeyCreateEncryptedData(keyPair1.publicKey, encryptionType.algorithm, plaintextData as CFData, nil)

        XCTAssertTrue(sut.deleteKey())

        let keyPair2 = try sut.makeKeyPair()
        let ciphertext2 = SecKeyCreateEncryptedData(keyPair2.publicKey, encryptionType.algorithm, plaintextData as CFData, nil)

        XCTAssertNotNil(ciphertext1)
        XCTAssertNotNil(ciphertext2)
        XCTAssertNotEqual(ciphertext1, plaintextData as CFData)
        XCTAssertNotEqual(ciphertext1, ciphertext2)
    }

    func testSegmentsStoredRSAKeysByContext() throws {
        let context1 = "\(#function)-context1"
        let context2 = "\(#function)-context2"
        let encryptionType: HybridEncryptionType = .rsaAESGCM

        let provider1 = KeychainHybridKeyProvider(context: context1, encryptionType: encryptionType)
        let provider2 = KeychainHybridKeyProvider(context: context2, encryptionType: encryptionType)

        provider1.deleteKey()
        provider2.deleteKey()

        let publicKey1 = try provider1.makeKeyPair().publicKey
        let publicKey2 = try provider2.makeKeyPair().publicKey

        let ciphertext1 = SecKeyCreateEncryptedData(publicKey1, encryptionType.algorithm, plaintextData as CFData, nil)
        let ciphertext2 = SecKeyCreateEncryptedData(publicKey2, encryptionType.algorithm, plaintextData as CFData, nil)

        XCTAssertNotNil(ciphertext1)
        XCTAssertNotNil(ciphertext2)
        XCTAssertNotEqual(ciphertext1, plaintextData as CFData)
        XCTAssertNotEqual(ciphertext1, ciphertext2)
    }

    #if !targetEnvironment(simulator) && os(iOS)

    func testStoresEllipticCurveKeysOnSecureEnclaveIfAvailable() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .eceisAESGCM)
        sut.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair = try sut.makeKeyPair()

        XCTAssertNil(SecKeyCopyExternalRepresentation(keyPair.privateKey, nil))
    }

    #endif

    // - MARK: Integration Tests

    func testHybridCryptorEncryptsAndDecryptsDataWithEllipticCurveKeys() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .eceisAESGCM)
        sut.prefersSecureEnclaveStorage = prefersSecureEnclaveStorage
        sut.deleteKey()

        let cryptor = HybridCryptor(keyProvider: sut)

        let encryptedData = try cryptor.encrypt(data: plaintextData)
        let decryptedData = try cryptor.decrypt(data: encryptedData)
        XCTAssertEqual(plaintextData, decryptedData)
    }

    func testHybridCryptorEncryptsAndDecryptsDataWithRSAKeys() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .rsaAESGCM)
        sut.deleteKey()

        let cryptor = HybridCryptor(keyProvider: sut)

        let encryptedData = try cryptor.encrypt(data: plaintextData)
        let decryptedData = try cryptor.decrypt(data: encryptedData)
        XCTAssertEqual(plaintextData, decryptedData)
    }

}
