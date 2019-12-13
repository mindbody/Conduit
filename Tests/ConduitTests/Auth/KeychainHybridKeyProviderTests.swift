//
//  KeychainHybridKeyProviderTests.swift
//  Conduit
//
//  Created by John Hammerlund on 12/10/19.
//

#if XCFRAMEWORK

import XCTest
@testable import Conduit

final class KeychainHybridKeyProviderTests: XCTestCase {

    private lazy var plaintextData: Data = {
        guard let path = Bundle(for: type(of: self)).url(forResource: "TestData", withExtension: "json"),
            let data = try? Data(contentsOf: path) else {
                fatalError("Test setup failed")
        }
        return data
    }()

    func testProvidesEllipticCurveKeys() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .eceisAESGCM)
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair1 = try sut.makeKeyPair()
        let keyPair2 = try sut.makeKeyPair()

        guard let publicKey1Data = SecKeyCopyExternalRepresentation(keyPair1.publicKey, nil),
            let publicKey2Data = SecKeyCopyExternalRepresentation(keyPair2.publicKey, nil) else {
                XCTFail("Failed to generate key pair")
                return
        }

        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair1.publicKey, .encrypt, algorithm))
        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair1.privateKey, .decrypt, algorithm))
        XCTAssertEqual(publicKey1Data, publicKey2Data)
    }

    func testDeletesStoredEllipticCurveKeys() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .eceisAESGCM)
        sut.deleteKey()

        let keyPair1 = try sut.makeKeyPair()

        XCTAssertTrue(sut.deleteKey())

        let keyPair2 = try sut.makeKeyPair()

        guard let publicKey1Data = SecKeyCopyExternalRepresentation(keyPair1.publicKey, nil),
            let publicKey2Data = SecKeyCopyExternalRepresentation(keyPair2.publicKey, nil) else {
                XCTFail("Failed to generate key pairs")
                return
        }

        XCTAssertNotEqual(publicKey1Data, publicKey2Data)
    }

    func testSegmentsStoredEllipticCurveKeysByContext() throws {
        let context1 = "\(#function)-context1"
        let context2 = "\(#function)-context2"

        let provider1 = KeychainHybridKeyProvider(context: context1, encryptionType: .eceisAESGCM)
        let provider2 = KeychainHybridKeyProvider(context: context2, encryptionType: .eceisAESGCM)

        provider1.deleteKey()
        provider2.deleteKey()

        let publicKey1 = try provider1.makeKeyPair().publicKey
        let publicKey2 = try provider2.makeKeyPair().publicKey

        guard let publicKey1Data = SecKeyCopyExternalRepresentation(publicKey1, nil),
            let publicKey2Data = SecKeyCopyExternalRepresentation(publicKey2, nil) else {
                XCTFail("Failed to generate key pair")
                return
        }

        XCTAssertNotEqual(publicKey1Data, publicKey2Data)
    }

    func testEncryptsAndDecryptsUsingRSA() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .rsaAESGCM)
        sut.deleteKey()

        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256AESGCM
        XCTAssertEqual(sut.keyAlgorithm, algorithm)

        let keyPair1 = try sut.makeKeyPair()
        let keyPair2 = try sut.makeKeyPair()

        guard let publicKey1Data = SecKeyCopyExternalRepresentation(keyPair1.publicKey, nil),
            let publicKey2Data = SecKeyCopyExternalRepresentation(keyPair2.publicKey, nil) else {
                XCTFail("Failed to generate key pair")
                return
        }

        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair1.publicKey, .encrypt, algorithm))
        XCTAssertTrue(SecKeyIsAlgorithmSupported(keyPair1.privateKey, .decrypt, algorithm))
        XCTAssertEqual(publicKey1Data, publicKey2Data)
    }

    func testDeletesStoredRSAKeys() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .rsaAESGCM)
        sut.deleteKey()

        let keyPair1 = try sut.makeKeyPair()
        guard let publicKey1Data = SecKeyCopyExternalRepresentation(keyPair1.publicKey, nil) else {
            XCTFail("Failed to generate key pairs")
            return
        }

        XCTAssertTrue(sut.deleteKey())

        let keyPair2 = try sut.makeKeyPair()

        guard let publicKey2Data = SecKeyCopyExternalRepresentation(keyPair2.publicKey, nil) else {
            XCTFail("Failed to generate key pairs")
            return
        }

        XCTAssertNotEqual(publicKey1Data, publicKey2Data)
    }

    func testSegmentsStoredRSAKeysByContext() throws {
        let context1 = "\(#function)-context1"
        let context2 = "\(#function)-context2"

        let provider1 = KeychainHybridKeyProvider(context: context1, encryptionType: .rsaAESGCM)
        let provider2 = KeychainHybridKeyProvider(context: context2, encryptionType: .rsaAESGCM)

        provider1.deleteKey()
        provider2.deleteKey()

        let publicKey1 = try provider1.makeKeyPair().publicKey
        let publicKey2 = try provider2.makeKeyPair().publicKey

        guard let publicKey1Data = SecKeyCopyExternalRepresentation(publicKey1, nil),
            let publicKey2Data = SecKeyCopyExternalRepresentation(publicKey2, nil) else {
                XCTFail("Failed to generate key pair")
                return
        }

        XCTAssertNotEqual(publicKey1Data, publicKey2Data)
    }

    #if !targetEnvironment(simulator) && !os(watchOS) && !os(tvOS)

    func testStoresEllipticCurveKeysOnSecureEnclaveIfAvailable() throws {
        let sut = KeychainHybridKeyProvider(context: #function, encryptionType: .eceisAESGCM)
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

#endif
