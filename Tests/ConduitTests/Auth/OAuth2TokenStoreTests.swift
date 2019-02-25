//
//  OAuth2TokenStoreTests.swift
//  Conduit
//
//  Created by Eneko Alonso on 2/25/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class OAuth2TokenStoreTests: XCTestCase {

    func testCustomStore() {
        let environment = OAuth2ServerEnvironment(scope: "foos", tokenGrantURL: URL(fileURLWithPath: "yay"))
        let clientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "foo", clientSecret: "bar",
                                                            environment: environment)
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let token = BearerToken(accessToken: "sat", expiration: Date.distantFuture)
        let store = CustomStore()

        // 1. Persist token
        XCTAssertTrue(store.store(token: token, for: clientConfiguration, with: authorization))

        // 2. Lock token & verify lock
        XCTAssertTrue(store.lockRefreshToken(timeout: 60, client: clientConfiguration, authorization: authorization))
        XCTAssertTrue(store.isRefreshTokenLockedFor(client: clientConfiguration, authorization: authorization))

        // 3. Unlock token & verify unlock
        XCTAssertTrue(store.unlockRefreshTokenFor(client: clientConfiguration, authorization: authorization))
        XCTAssertFalse(store.isRefreshTokenLockedFor(client: clientConfiguration, authorization: authorization))

        // 4. Retrieve token & compare
        var storedToken: BearerToken? = store.tokenFor(client: clientConfiguration, authorization: authorization)
        XCTAssertEqual(token, storedToken)

        // 5. Clear token & verify
        let nilToken: BearerToken? = nil
        XCTAssertTrue(store.store(token: nilToken, for: clientConfiguration, with: authorization))
        storedToken = store.tokenFor(client: clientConfiguration, authorization: authorization)
        XCTAssertNil(storedToken)
    }

    private class CustomStore: OAuth2TokenStore {
        var tokenMap: [String: OAuth2Token] = [:]
        var tokenLocks: [String: Date] = [:]

        func store<Token>(token: Token?, for client: OAuth2ClientConfiguration,
                          with authorization: OAuth2Authorization) -> Bool where Token: DataConvertible, Token: OAuth2Token {
            let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
            tokenMap[identifier] = token
            return true
        }

        func tokenFor<Token>(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Token? where Token: DataConvertible, Token: OAuth2Token {
            let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
            return tokenMap[identifier] as? Token
        }

        func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
            let lockIdentifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
            tokenLocks[lockIdentifier] = Date().addingTimeInterval(3_600)
            return true
        }

        func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
            let lockIdentifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
            tokenLocks[lockIdentifier] = nil
            return true
        }

        func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
            let lockIdentifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
            return tokenLocks[lockIdentifier]
        }
    }
}
