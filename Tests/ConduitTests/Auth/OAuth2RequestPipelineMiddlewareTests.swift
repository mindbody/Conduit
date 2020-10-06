//
//  OAuth2RequestPipelineMiddlewareTests.swift
//  Conduit
//
//  Created by John Hammerlund on 7/7/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import XCTest
@testable import Conduit

class CustomRefreshTokenGrantStrategy: OAuth2TokenGrantStrategy {

    enum Error: Swift.Error {
        case didExecute
    }

    func issueToken(completion: @escaping (Result<BearerToken>) -> Void) {
        completion(.error(CustomRefreshTokenGrantStrategy.Error.didExecute))
    }

    func issueToken() throws -> BearerToken {
        return BearerToken(accessToken: "", expiration: Date())
    }

}

struct CustomRefreshTokenGrantStrategyFactory: OAuth2RefreshStrategyFactory {
    func make(refreshToken: String, clientConfiguration: OAuth2ClientConfiguration) -> OAuth2TokenGrantStrategy {
        return CustomRefreshTokenGrantStrategy()
    }
}

// swiftlint:disable type_body_length
class OAuth2RequestPipelineMiddlewareTests: XCTestCase {

    let validClientID = "test_client"
    let validClientSecret = "test_secret"
    let guestUsername = "test_user"
    let guestPassword = "hunter2"

    let randomTokenAccessToken = "abc123!!"

    private func makeMockClientConfiguration() throws -> OAuth2ClientConfiguration {
        let mockServerEnvironment = OAuth2ServerEnvironment(scope: "urn:everything", tokenGrantURL: try URL(absoluteString: "http://localhost:3333/get"))
        let mockClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: "herp", clientSecret: "derp", environment: mockServerEnvironment,
                                                                guestUsername: "clientuser", guestPassword: "abc123")
        return mockClientConfiguration
    }

    private func makeValidClientConfiguration() throws -> OAuth2ClientConfiguration {
        let validServerEnvironment = OAuth2ServerEnvironment(scope: "all the things",
                                                             tokenGrantURL: try URL(absoluteString: "http://localhost:5000/oauth2/issue/token"))
        let validClientConfiguration = OAuth2ClientConfiguration(clientIdentifier: validClientID, clientSecret: validClientSecret,
                                                                 environment: validServerEnvironment)
        return validClientConfiguration
    }

    private func makeDummyRequest() throws -> URLRequest {
        let requestBuilder = HTTPRequestBuilder(url: try URL(absoluteString: "http://localhost:3333/post"))
        requestBuilder.bodyParameters = ["key": "value"]
        requestBuilder.method = .POST
        requestBuilder.serializer = JSONRequestSerializer()

        return try requestBuilder.build()
    }

    func testAppliesBearerHeaderIfValidTokenExists() throws {
        let randomToken = BearerToken(accessToken: randomTokenAccessToken, refreshToken: "notused", expiration: Date().addingTimeInterval(1_000_000))
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let validClientConfiguration = try makeValidClientConfiguration()

        let tokenStorage = OAuth2TokenMemoryStore()
        tokenStorage.store(token: randomToken, for: validClientConfiguration, with: authorization)

        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let decorateRequestExpectation = expectation(description: "request immediately decorated")
        sut.prepareForTransport(request: request) { result in
            guard case .value(let request) = result else {
                XCTFail("No value")
                return
            }
            XCTAssert(request.allHTTPHeaderFields?["Authorization"] == randomToken.authorizationHeaderValue)
            decorateRequestExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testRefreshesBearerTokenIfExpired() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let validClientConfiguration = try makeValidClientConfiguration()
        let request = try makeDummyRequest()
        let tokenStorage = OAuth2TokenMemoryStore()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let refreshTokenExpectation = expectation(description: "token refreshed")

        let clientCredentialsStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: validClientConfiguration)
        clientCredentialsStrategy.issueToken { result in
            guard let token = result.value else {
                XCTFail("No token")
                return
            }
            let expiredToken = BearerToken(accessToken: token.accessToken, refreshToken: token.refreshToken, expiration: Date())

            tokenStorage.store(token: expiredToken, for: validClientConfiguration, with: authorization)

            sut.prepareForTransport(request: request) { result in
                guard let request = result.value else {
                    XCTFail("No value")
                    return
                }
                let authorizationHeader = request.allHTTPHeaderFields?["Authorization"]
                XCTAssertTrue(authorizationHeader?.contains("Bearer") == true)
                XCTAssert(authorizationHeader?.contains(expiredToken.accessToken) == false)

                refreshTokenExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2)
    }

    func testAllowsCustomTokenRefreshGrants() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let validClientConfiguration = try makeValidClientConfiguration()
        let request = try makeDummyRequest()
        let tokenStorage = OAuth2TokenMemoryStore()
        var sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        sut.refreshStrategyFactory = CustomRefreshTokenGrantStrategyFactory()

        let refreshTokenExpectation = expectation(description: "token refreshed")

        let clientCredentialsStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: validClientConfiguration)
        clientCredentialsStrategy.issueToken { result in
            guard let token = result.value else {
                XCTFail("No token")
                return
            }
            let expiredToken = BearerToken(accessToken: token.accessToken, refreshToken: token.refreshToken, expiration: Date())

            tokenStorage.store(token: expiredToken, for: validClientConfiguration, with: authorization)

            sut.prepareForTransport(request: request) { result in
                guard result.error is CustomRefreshTokenGrantStrategy.Error else {
                    XCTFail("Custom strategy ignored")
                    return
                }

                refreshTokenExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2)
    }

    func testEmptyTokenRefreshStrategyPreventsRefreshes() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let validClientConfiguration = try makeValidClientConfiguration()
        let request = try makeDummyRequest()
        let tokenStorage = OAuth2TokenMemoryStore()
        var sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        sut.refreshStrategyFactory = nil

        let tokenInvalidatedExpectation = expectation(description: "token refresh ignored & token invalidated")

        let clientCredentialsStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: validClientConfiguration)
        clientCredentialsStrategy.issueToken { result in
            guard let token = result.value else {
                XCTFail("No token")
                return
            }
            let expiredToken = BearerToken(accessToken: token.accessToken, refreshToken: token.refreshToken, expiration: Date())

            tokenStorage.store(token: expiredToken, for: validClientConfiguration, with: authorization)

            sut.prepareForTransport(request: request) { result in
                guard let error = result.error, case OAuth2Error.clientFailure(_, _) = error else {
                    XCTFail("Custom strategy ignored")
                    return
                }

                tokenInvalidatedExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2)
    }

    func testAttemptsPasswordGrantWithGuestCredentialsIfTheyExist() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .client)
        var validClientConfiguration = try makeValidClientConfiguration()

        let request = try makeDummyRequest()
        validClientConfiguration.guestUsername = "test_user"
        validClientConfiguration.guestPassword = "hunter2"
        var sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization,
                                                  tokenStorage: OAuth2TokenMemoryStore())

        let tokenFetchedExpectation = expectation(description: "token fetched")
        sut.prepareForTransport(request: request) { result in
            guard case .value(let request) = result else {
                XCTFail("No value")
                return
            }
            XCTAssert(request.allHTTPHeaderFields?["Authorization"]?.contains("Bearer") == true)
            tokenFetchedExpectation.fulfill()
        }

        /// Update guest user creds to prove code flow

        validClientConfiguration.guestUsername = "invalid_user"
        validClientConfiguration.guestPassword = "invalid_pass"
        sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization,
                                              tokenStorage: OAuth2TokenMemoryStore())

        let tokenFetchAttemptedExpectation = expectation(description: "token fetch failed")
        sut.prepareForTransport(request: request) { result in
            XCTAssertNotNil(result.error)
            tokenFetchAttemptedExpectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testAttemptsClientCredentialsGrantIfGuestCredentialsDontExist() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .client)
        var validClientConfiguration = try makeValidClientConfiguration()

        let request = try makeDummyRequest()
        var sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization,
                                                  tokenStorage: OAuth2TokenMemoryStore())

        let tokenFetchedExpectation = expectation(description: "token fetched")
        sut.prepareForTransport(request: request) { result in
            guard case .value(let request) = result else {
                XCTFail("No value")
                return
            }
            XCTAssert(request.allHTTPHeaderFields?["Authorization"]?.contains("Bearer") == true)
            tokenFetchedExpectation.fulfill()
        }

        /// Update client creds to prove code flow

        validClientConfiguration.clientIdentifier = "invalid_client"
        validClientConfiguration.clientSecret = "invalid_secret"
        sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization,
                                              tokenStorage: OAuth2TokenMemoryStore())

        let tokenFetchAttemptedExpectation = expectation(description: "token fetch failed")
        sut.prepareForTransport(request: request) { result in
            XCTAssertNotNil(result.error)
            tokenFetchAttemptedExpectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFailsForBearerUserAuthIfNoTokenExists() throws {
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let validClientConfiguration = try makeValidClientConfiguration()

        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization,
                                                  tokenStorage: OAuth2TokenMemoryStore())
        let decorationFailedExpectation = expectation(description: "decoration failed")

        sut.prepareForTransport(request: request) { result in
            XCTAssertNotNil(result.error)
            decorationFailedExpectation.fulfill()
        }

        waitForExpectations(timeout: 0.1)
    }

    func testNotifiesMigratorPreAndPostFetchTokenHooksForRefreshes() throws {
        let randomToken = BearerToken(accessToken: randomTokenAccessToken, refreshToken: "notused", expiration: Date())
        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let mockClientConfiguration = try makeMockClientConfiguration()

        let tokenStorage = OAuth2TokenMemoryStore()
        tokenStorage.store(token: randomToken, for: mockClientConfiguration, with: authorization)

        let request = try makeDummyRequest()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: mockClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let calledPreFetchHookExpectation = expectation(description: "called pre-fetch hook")
        let calledPostFetchHookExpectation = expectation(description: "called pre-fetch hook")
        calledPreFetchHookExpectation.assertForOverFulfill = false
        calledPostFetchHookExpectation.assertForOverFulfill = false

        Auth.Migrator.registerPreFetchHook { _, _, _  in
            calledPreFetchHookExpectation.fulfill()
        }

        Auth.Migrator.registerPostFetchHook { _, _, _  in
            calledPostFetchHookExpectation.fulfill()
        }

        sut.prepareForTransport(request: request) { _ in
            // Pass
        }

        waitForExpectations(timeout: 1)
    }

    func testCoordinatesRefreshesBetweenMultipleSessions() throws {
        /// Simulates multiple sessions (different processes) triggering token refreshes at once

        let authorization = OAuth2Authorization(type: .bearer, level: .user)
        let validClientConfiguration = try makeValidClientConfiguration()
        let request = try makeDummyRequest()
        let tokenStorage = OAuth2TokenMemoryStore()
        let sut = OAuth2RequestPipelineMiddleware(clientConfiguration: validClientConfiguration, authorization: authorization, tokenStorage: tokenStorage)

        let refreshTokenExpectation = expectation(description: "token refreshed")
        let numSessions = 15
        refreshTokenExpectation.expectedFulfillmentCount = numSessions
        var authorizationHeaders: [String] = []
        let arrayQueue = DispatchQueue(label: #function)

        let clientCredentialsStrategy = OAuth2ClientCredentialsTokenGrantStrategy(clientConfiguration: validClientConfiguration)
        let issuedToken = try clientCredentialsStrategy.issueToken()

        let expiredToken = BearerToken(accessToken: issuedToken.accessToken, refreshToken: issuedToken.refreshToken, expiration: Date())

        tokenStorage.store(token: expiredToken, for: validClientConfiguration, with: authorization)

        for _ in 0..<numSessions {
            sut.prepareForTransport(request: request) { result in
                guard let request = result.value,
                    let authorizationHeader = request.allHTTPHeaderFields?["Authorization"] else {
                        XCTFail("No value")
                        return
                }
                arrayQueue.sync {
                    authorizationHeaders.append(authorizationHeader)
                    refreshTokenExpectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5)

        let firstHeader = authorizationHeaders[0]
        XCTAssertFalse(firstHeader.contains(expiredToken.accessToken))
        for header in authorizationHeaders {
            XCTAssertEqual(firstHeader, header)
        }
    }
}
// swiftlint:enable type_body_length
