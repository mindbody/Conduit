//
//  OAuth2TokenStorageTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2TokenStorageTests: XCTestCase {

    let mockToken = BearerToken(accessToken: "herp", refreshToken: "derp", expiration: Date().addingTimeInterval(10_000))
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

    private func verifyRefreshTokenLockOperations<Token: OAuth2Token & DataConvertible>(sut: OAuth2TokenStore, with token: Token) throws {
        let mockClientConfiguration = try makeMockClientConfiguration()
        sut.unlockRefreshTokenFor(client: mockClientConfiguration, authorization: mockAuthorization)
        XCTAssertFalse(sut.isRefreshTokenLockedFor(client: mockClientConfiguration, authorization: mockAuthorization))
        sut.lockRefreshToken(timeout: 0.3, client: mockClientConfiguration, authorization: mockAuthorization)
        XCTAssert(sut.isRefreshTokenLockedFor(client: mockClientConfiguration, authorization: mockAuthorization))

        let waitExpectation = expectation(description: "refresh token unlocked")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.31) {
            XCTAssertFalse(sut.isRefreshTokenLockedFor(client: mockClientConfiguration, authorization: self.mockAuthorization))
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testKeychainStorageOperations() throws {
        let sut = OAuth2TokenKeychainStore(service: UUID().uuidString)
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)
    }

    func testStandardUserDefaultsStorageOperations() throws {
        let sut = OAuth2TokenUserDefaultsStore(userDefaults: .standard, context: UUID().uuidString)
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)
    }

    func testDomainUserDefaultsStorageOperations() throws {
        let groupIdentifier = "group.com.mindbodyonline.ConduitTests"
        guard let userDefaults = UserDefaults(suiteName: groupIdentifier) else {
            XCTFail("Failed to create sandboxed application group (this won't work with codesigning)")
            return
        }
        let sut = OAuth2TokenUserDefaultsStore(userDefaults: userDefaults)
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)
    }

    #if !os(tvOS)
    func testFileStorageOperations() throws {
        let storagePath = NSTemporaryDirectory().appending(UUID().uuidString)
        let storageURL = URL(fileURLWithPath: storagePath)
        var sut = OAuth2TokenFileStore(options: OAuth2TokenFileStoreOptions(storageDirectory: storageURL))
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)
        #if !os(macOS)
        // File protection options are unavailable on Mac
        sut = OAuth2TokenFileStore(options: OAuth2TokenFileStoreOptions(storageDirectory: storageURL,
                                                                        coordinatesFileAccess: true,
                                                                        tokenWritingOptions: [.atomic, .completeFileProtection]))
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)
        #endif
        sut = OAuth2TokenFileStore(options: OAuth2TokenFileStoreOptions(storageDirectory: storageURL, coordinatesFileAccess: true))
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)

        try FileManager.default.removeItem(at: storageURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storagePath))
    }
    #endif

    func testMemoryStorageOperations() throws {
        let sut = OAuth2TokenMemoryStore()
        try verifyTokenStorageOperations(sut: sut, with: mockToken)
        try verifyRefreshTokenLockOperations(sut: sut, with: mockToken)
    }
}
