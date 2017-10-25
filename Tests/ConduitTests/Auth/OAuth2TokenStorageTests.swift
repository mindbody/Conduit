//
//  OAuth2TokenStorageTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class OAuth2TokenStorageTests: XCTestCase {

    let mockToken = BearerToken(accessToken: "herp", refreshToken: "derp", expiration: Date().addingTimeInterval(10_000))
    let mockLegacyToken = BearerOAuth2Token(accessToken: "herp", refreshToken: "derp", expiration: Date().addingTimeInterval(10_000))
    let mockAuthorization = OAuth2Authorization(type: .bearer, level: .user)

    private func makeMockClientConfiguration() throws -> OAuth2ClientConfiguration {
        let mockServerEnvironment = OAuth2ServerEnvironment(tokenGrantURL: try URL(absoluteString: "http://localhost:3333/get"))
        let mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp",
                                                                environment: mockServerEnvironment, guestUsername: "clientuser", guestPassword: "abc123")
        return mockClientConfiguration
    }

    private func verifyTokenStorageOperations<Token: OAuth2Token & DataConvertible>(sut: OAuth2TokenStore, with token: Token) throws {
        let mockClientConfiguration = try makeMockClientConfiguration()
        sut.removeAllTokensFor(client: mockClientConfiguration)
        XCTAssert(sut.store(token: token, for: mockClientConfiguration, with: mockAuthorization))
        var storedToken: Token? = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
        XCTAssertNotNil(storedToken)
        sut.removeTokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
        storedToken = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
        XCTAssertNil(storedToken)
        XCTAssert(sut.store(token: token, for: mockClientConfiguration, with: mockAuthorization))
        sut.removeAllTokensFor(client: mockClientConfiguration)
        storedToken = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
        XCTAssertNil(storedToken)
    }

    func testKeychainStorageOperations() throws {
        let sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
    }

    func testUserDefaultsStorageOperations() throws {
        let sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
    }

#if !os(tvOS)
    func testFileStorageOperations() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        let sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
    }
#endif

    func testMemoryStorageOperations() throws {
        let sut = OAuth2TokenMemoryStore()
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
    }

    func testLegacyKeychainStorageOperations() throws {
        let sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        try verifyTokenStorageOperations(sut: sut, with: mockLegacyToken)
    }

    func testLegacyUserDefaultsStorageOperations() throws {
        let sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        try verifyTokenStorageOperations(sut: sut, with: mockLegacyToken)
    }

    #if !os(tvOS)
    func testLegacyFileStorageOperations() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        let sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        try verifyTokenStorageOperations(sut: sut, with: mockLegacyToken)
    }
    #endif

    func testLegacyMemoryStorageOperations() throws {
        let sut = OAuth2TokenMemoryStore()
        try verifyTokenStorageOperations(sut: sut, with: mockLegacyToken)
    }

    private func validateLegacyTokenMigration(sut: OAuth2TokenStore) throws {
        let mockClientConfiguration = try makeMockClientConfiguration()
        sut.store(token: mockLegacyToken, for: mockClientConfiguration, with: mockAuthorization)
        guard let legacyToken: BearerOAuth2Token = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) else {
            XCTFail("Failed to get token")
            return
        }

        let newToken = legacyToken.converted
        sut.store(token: newToken, for: mockClientConfiguration, with: mockAuthorization)
        guard let migratedToken: BearerToken = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) else {
            XCTFail("Failed to get token")
            return
        }
        XCTAssert(migratedToken.accessToken == mockLegacyToken.accessToken)
        XCTAssert(migratedToken.expiration == mockLegacyToken.expiration)
        XCTAssert(migratedToken.refreshToken == mockLegacyToken.refreshToken)

        sut.removeTokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
    }

    func testLegacyKeychainTokenMigration() throws {
        let sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        try validateLegacyTokenMigration(sut: sut)
    }

    func testLegacyUserDefaultsTokenMigration() throws {
        let sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        try validateLegacyTokenMigration(sut: sut)
    }

    #if !os(tvOS)
    func testLegacyFileStorageTokenMigration() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        let sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        try validateLegacyTokenMigration(sut: sut)
    }
    #endif

    func testLegacyMemoryStorageTokenMigration() throws {
        let sut = OAuth2TokenMemoryStore()
        try validateLegacyTokenMigration(sut: sut)
    }
}
