//
//  AuthMigratorTests.swift
//  Conduit
//
//  Created by John Hammerlund on 6/11/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class AuthMigratorTests: XCTestCase {

    let validClientID = "test_client"
    let validClientSecret = "test_secret"

    private func makeValidClientConfiguration() throws -> OAuth2ClientConfiguration {
        let validServerEnvironment = OAuth2ServerEnvironment(scope: "all the things",
                                                             tokenGrantURL: try URL(absoluteString: "http://localhost:5000/oauth2/issue/token"))
        let validClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: validClientID, clientSecret: validClientSecret,
                                                                 environment: validServerEnvironment)
        return validClientConfiguration
    }

    func testExternalTokenRefreshFailsWithEmptyToken() throws {
        let sessionClient = URLSessionClient()
        let tokenStorage = OAuth2TokenMemoryStore()
        let middleware = OAuth2RequestPipelineMiddleware(clientConfiguration: try makeValidClientConfiguration(),
                                                         authorization: OAuth2Authorization(type: .bearer, level: .client),
                                                         tokenStorage: tokenStorage)
        let refreshHandlerExpectation = expectation(description: "token refresh handler executed")

        Auth.Migrator.refreshBearerTokenWithin(sessionClient: sessionClient, middleware: middleware) { result in
            guard let error = result.error, case OAuth2Error.clientFailure(_, _) = error else {
                XCTFail("expected client error")
                refreshHandlerExpectation.fulfill()
                return
            }
            refreshHandlerExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testExternalTokenRefreshFailsWithInvalidToken() throws {
        let sessionClient = URLSessionClient()
        let tokenStorage = OAuth2TokenMemoryStore()
        let clientConfiguration = try makeValidClientConfiguration()
        let authorization = OAuth2Authorization(type: .bearer, level: .client)
        let middleware = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                         authorization: authorization,
                                                         tokenStorage: tokenStorage)
        let grant = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: clientConfiguration)
        let token = try grant.issueToken()
        let invalidToken = BearerToken(accessToken: token.accessToken, refreshToken: "invalid", expiration: token.expiration)
        tokenStorage.store(token: invalidToken, for: clientConfiguration, with: authorization)

        let refreshHandlerExpectation = expectation(description: "token refresh handler executed")

        Auth.Migrator.refreshBearerTokenWithin(sessionClient: sessionClient, middleware: middleware) { result in
            guard let error = result.error, case OAuth2Error.clientFailure(_, _) = error else {
                XCTFail("expected client error")
                refreshHandlerExpectation.fulfill()
                return
            }
            refreshHandlerExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testExternalTokenRefreshSucceedsWithValidToken() throws {
        let sessionClient = URLSessionClient()
        let tokenStorage = OAuth2TokenMemoryStore()
        let clientConfiguration = try makeValidClientConfiguration()
        let authorization = OAuth2Authorization(type: .bearer, level: .client)
        let middleware = OAuth2RequestPipelineMiddleware(clientConfiguration: clientConfiguration,
                                                         authorization: authorization,
                                                         tokenStorage: tokenStorage)
        let grant = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: clientConfiguration)
        let token = try grant.issueToken()
        tokenStorage.store(token: token, for: clientConfiguration, with: authorization)

        let refreshHandlerExpectation = expectation(description: "token refresh handler executed")

        Auth.Migrator.refreshBearerTokenWithin(sessionClient: sessionClient, middleware: middleware) { result in
            XCTAssertNotNil(result.value)
            refreshHandlerExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

}
