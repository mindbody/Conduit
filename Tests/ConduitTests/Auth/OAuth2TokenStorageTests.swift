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
            ("testUserDefaultsStorageOperations", testUserDefaultsStorageOperations),
            ("testFileStorageOperations", testFileStorageOperations),
            ("testMemoryStorageOperations", testMemoryStorageOperations)
        ]
    }()
}

class OAuth2TokenStorageTests: XCTestCase {

    var mockServerEnvironment: OAuth2ServerEnvironment!
    var mockClientConfiguration: OAuth2ClientConfiguration!
    let mockToken = BearerOAuth2Token(accessToken: "herp", refreshToken: "derp", expiration: Date().addingTimeInterval(10_000))
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

    private func verifyTokenStorageOperations() {
        sut.removeAllTokensFor(client: mockClientConfiguration)
        XCTAssert(sut.store(token: mockToken, for: mockClientConfiguration, with: mockAuthorization))
        XCTAssert(sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) != nil)
        XCTAssert(sut.store(token: nil, for: mockClientConfiguration, with: mockAuthorization))
        XCTAssert(sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) == nil)
        XCTAssert(sut.store(token: mockToken, for: mockClientConfiguration, with: mockAuthorization))
        sut.removeAllTokensFor(client: mockClientConfiguration)
        XCTAssert(sut.tokenFor(client: mockClientConfiguration, authorization: mockAuthorization) == nil)
    }

#if !os(Linux)
    func testKeychainStorageOperations() {
        sut = OAuth2TokenKeychainStore(service: "com.mindbodyonline.Conduit.testService")
        verifyTokenStorageOperations()
    }
#endif

    func testUserDefaultsStorageOperations() {
        sut = OAuth2TokenDiskStore(storageMethod: .userDefaults)
        verifyTokenStorageOperations()
    }

#if !os(tvOS)
    func testFileStorageOperations() throws {
        let storagePath = NSTemporaryDirectory().appending("oauth-token.bin")
        let storageURL = URL(fileURLWithPath: storagePath)
        sut = OAuth2TokenDiskStore(storageMethod: .url(storageURL))
        verifyTokenStorageOperations()
    }
#endif

    func testMemoryStorageOperations() {
        sut = OAuth2TokenMemoryStore()
        verifyTokenStorageOperations()
    }
}
