//
//  OAuth2TokenStorageTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

extension OAuth2TokenStorageTests {
    static var allTests: [(String, (OAuth2TokenStorageTests) -> () throws -> Void)] = {
        return [
            ("testMemoryStorageOperations", testMemoryStorageOperations)
        ]
    }()
}

class OAuth2TokenStorageTests: XCTestCase {

    var mockServerEnvironment: OAuth2ServerEnvironment!
    var mockClientConfiguration: OAuth2ClientConfiguration!
    let mockToken = BearerToken(accessToken: "herp", refreshToken: "derp", expiration: Date().addingTimeInterval(10_000))
    let mockLegacyToken = BearerOAuth2Token(accessToken: "herp", refreshToken: "derp", expiration: Date().addingTimeInterval(10_000))
    let mockAuthorization = OAuth2Authorization(type: .bearer, level: .user)
    var sut: OAuth2TokenStore!

    override func setUp() {
        super.setUp()

        do {
            mockServerEnvironment = OAuth2ServerEnvironment(tokenGrantURL: try URL(absoluteString: "http://localhost:3333/get"))
            mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp",
                                                                environment: mockServerEnvironment, guestUsername: "clientuser", guestPassword: "abc123")
        }
        catch {
            XCTFail()
        }
    }

    private func verifyTokenStorageOperations<Token: OAuth2Token & DataConvertible>(with token: Token) {
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

#if !os(Linux)
    func testKeychainStorageOperations() {
        sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        verifyTokenStorageOperations(with: mockToken)
    }

    func testUserDefaultsStorageOperations() {
        sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        verifyTokenStorageOperations(with: mockToken)
    }

#if !os(tvOS)
    func testFileStorageOperations() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        verifyTokenStorageOperations(with: mockToken)
    }
#endif

#endif

    func testMemoryStorageOperations() {
        sut = OAuth2TokenMemoryStore()
        verifyTokenStorageOperations(with: mockToken)
    }

#if !os(Linux)
    func testLegacyKeychainStorageOperations() {
        sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        verifyTokenStorageOperations(with: mockLegacyToken)
    }

    func testLegacyUserDefaultsStorageOperations() {
        sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        verifyTokenStorageOperations(with: mockLegacyToken)
    }

#if !os(tvOS)
    func testLegacyFileStorageOperations() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        verifyTokenStorageOperations(with: mockLegacyToken)
    }
#endif

#endif

    func testLegacyMemoryStorageOperations() {
        sut = OAuth2TokenMemoryStore()
        verifyTokenStorageOperations(with: mockLegacyToken)
    }

    private func validateLegacyTokenMigration() {
        sut.store(token: mockLegacyToken, for: mockClientConfiguration, with: mockAuthorization)
        guard let legacyToken: BearerOAuth2Token = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) else {
            XCTFail()
            return
        }

        let newToken = legacyToken.converted
        sut.store(token: newToken, for: mockClientConfiguration, with: mockAuthorization)
        guard let migratedToken: BearerToken = sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) else {
            XCTFail()
            return
        }
        XCTAssert(migratedToken.accessToken == mockLegacyToken.accessToken)
        XCTAssert(migratedToken.expiration == mockLegacyToken.expiration)
        XCTAssert(migratedToken.refreshToken == mockLegacyToken.refreshToken)

        sut.removeTokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
    }

#if !os(Linux)
    func testLegacyKeychainTokenMigration() {
        sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        validateLegacyTokenMigration()
    }

    func testLegacyUserDefaultsTokenMigration() {
        sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        validateLegacyTokenMigration()
    }

#if !os(tvOS)
    func testLegacyFileStorageTokenMigration() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        validateLegacyTokenMigration()
    }
#endif

#endif

    func testLegacyMemoryStorageTokenMigration() {
        sut = OAuth2TokenMemoryStore()
        validateLegacyTokenMigration()
    }
}
