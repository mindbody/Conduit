//
//  OAuth2TokenEncryptedStoreTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2TokenEncryptedStoreTests: XCTestCase {

    func testCipher() throws {
        let sut = ACMECipher()
        let token = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date.distantFuture)
        let ciphertext = try sut.encrypt(token: token)
        let decrypted: BearerToken? = try sut.decrypt(data: ciphertext)
        XCTAssertEqual(token, decrypted)
    }

    func testEncryptedStore() throws {
        let environment = OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "local"))
        let client = OAuth2ClientConfiguration(clientIdentifier: "client", clientSecret: "secret",
                                               environment: environment)
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let sut = ACMEEncryptedStore()

        // 1. Store token
        let token = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date.distantFuture)
        XCTAssertTrue(sut.store(token: token, for: client, with: authorization))

        // 2. Retrieve token
        let retrieved: BearerToken? = sut.tokenFor(client: client, authorization: authorization)
        XCTAssertEqual(token, retrieved)
    }

    /// Test tokens stores unencrypted in UserDefaults can be retrieved without decryption
    func testTokenEncryptedMigration() {
        let environment = OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "local"))
        let client = OAuth2ClientConfiguration(clientIdentifier: "client", clientSecret: "secret",
                                               environment: environment)
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let sut = OAuth2TokenUserDefaultsStore(userDefaults: UserDefaults(), context: "")

        // 1. Store unencrypted token
        let token = BearerToken(accessToken: "foo", refreshToken: "bar", expiration: Date.distantFuture)
        XCTAssertTrue(sut.store(token: token, for: client, with: authorization))

        // 2. Configure cypher
        sut.tokenCipher = ACMECipher()

        // 3. Retrieve token & validate
        let retrieved: BearerToken? = sut.tokenFor(client: client, authorization: authorization)
        XCTAssertEqual(token, retrieved)
    }

    private class ACMEEncryptedStore: OAuth2TokenEncryptedStore {
        var tokenCipher: OAuth2TokenCipher?
        var tokens: [String: Data] = [:]

        init() {
            tokenCipher = ACMECipher()
        }

        func store<Token>(token: Token?, for client: OAuth2ClientConfiguration,
                          with authorization: OAuth2Authorization) -> Bool where Token: DataConvertible, Token: OAuth2Token {
            let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
            tokens[identifier] = tokenData(from: token)
            return true
        }

        func tokenFor<Token>(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Token? where Token: DataConvertible, Token: OAuth2Token {
            let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
            return tokens[identifier].flatMap { token(from: $0) }
        }

        func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
            return true
        }

        func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
            return true
        }

        func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
            return nil
        }
    }

    private class ACMECipher: OAuth2TokenCipher {
        func encrypt<Token>(token: Token) throws -> Data where Token: DataConvertible, Token: OAuth2Token {
            let superEncryptedToken = try token.serialized().reversed() // Super-secret encryption :D
            return Data(bytes: superEncryptedToken)
        }

        func decrypt<Token>(data: Data) throws -> Token where Token: DataConvertible, Token: OAuth2Token {
            let decryptedToken = data.reversed()
            return try Token(serializedData: Data(bytes: decryptedToken))
        }
    }

}
